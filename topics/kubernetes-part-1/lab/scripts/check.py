"""Challenge grading. Fault checks run after configuration and Service pass."""

import argparse
import hashlib
import json
import signal
import sys
import time
from urllib.parse import urlsplit

from lab import (Cluster, CONTEXT, NAME, BACKEND_NAME, BACKEND_MESSAGE, ROOT, LabError, WaitTimeout,
                 RetrySample, connection, endpoint_uids, fault_lock, interrupted,
                 ready, environment, server_container)


def recovery_fault(cluster, pods):
    target = pods[0]
    cluster.delete(target)
    def replaced():
        new = cluster.healthy(len(pods))
        return new if all(p['metadata']['uid'] != target['metadata']['uid'] for p in new) else None
    new = cluster.wait('대체 Pod 복구', replaced)
    cluster.wait('복구 endpoint 반영', lambda: endpoint_uids(cluster.slices()) == {
        p['metadata']['uid'] for p in new})
    cluster.traffic({p['metadata']['name'] for p in new})


def backend_url(value, namespace):
    try:
        url = urlsplit(value)
        valid = (url.scheme == 'http' and url.hostname in {
            BACKEND_NAME, f'{BACKEND_NAME}.{namespace}',
            f'{BACKEND_NAME}.{namespace}.svc', f'{BACKEND_NAME}.{namespace}.svc.cluster.local'}
            and url.port in (None, 80) and url.path in ('', '/')
            and not (url.username or url.password or url.query or url.fragment))
    except ValueError:
        valid = False
    if not valid:
        raise LabError('BACKEND_URL은 같은 namespace의 team-backend Service HTTP 주소(80번 포트)여야 한다.')


def backend_check(cluster):
    # Check both topology and real HTTP traffic; a direct backend curl alone
    # would not prove that the frontend calls the backend Service.
    deployment = cluster.get('deployment/' + BACKEND_NAME)
    if deployment['spec'].get('replicas', 1) != 1:
        raise LabError('백엔드 replicas는 1이어야 한다.')
    backend_pods = cluster.wait('백엔드 수렴', lambda: cluster.healthy(1, BACKEND_NAME))
    connection(cluster.get('service/' + BACKEND_NAME), backend_pods, [], check_endpoints=False)
    cluster.wait('백엔드 Service 연결', lambda: _connection(cluster, backend_pods, BACKEND_NAME))
    _, frontend_pods = cluster.snapshot()
    if len(frontend_pods) < 2 or not all(ready(p) for p in frontend_pods):
        raise LabError('백엔드 연결을 확인할 Ready 프론트가 두 개 이상 필요하다.')
    for pod in frontend_pods:
        container = server_container(pod)
        if environment(container).get('SERVER_ROLE', 'frontend') != 'frontend':
            raise LabError('프론트 SERVER_ROLE을 확인한다.')
        backend_url(environment(container).get('BACKEND_URL', ''), cluster.namespace)
    _connection(cluster, frontend_pods)
    target = backend_pods[0]['metadata']
    cluster.traffic({p['metadata']['name'] for p in frontend_pods}, minimum=2, path='/api',
                    backend={'backend_message': BACKEND_MESSAGE,
                             'backend_pod': target['name'], 'backend_uid': target['uid']})
    current = cluster.healthy(1, BACKEND_NAME)[0]
    if current['metadata']['uid'] != target['uid']:
        raise LabError('검사 중 백엔드 Pod가 교체되었다. 다시 검사한다.')
    return True


def grade(cluster, faults=True):
    points = 0
    passed = {}
    def item(key, title, value, test):
        nonlocal points
        deadline = cluster.deadline
        # An unsolved item must not consume the budget of every other item.
        cluster.deadline = min(deadline, time.monotonic() + 30)
        try:
            result = test()
            points += value
            passed[key] = result if result is not None else True
            print(f'[통과 +{value}] {title}', flush=True)
        except WaitTimeout as e:
            print(f'[대기 시간 초과 +0] {title}: {e}', flush=True)
        except RetrySample as e:
            print(f'[재검사 필요 +0] {title}: {e}', flush=True)
        except LabError as e:
            print(f'[미통과 +0] {title}: {e}', flush=True)
        finally:
            cluster.deadline = deadline

    cluster.pin_resources()
    d = cluster.get('deployment/' + NAME)
    def servers():
        if d['spec'].get('replicas', 1) != 3:
            raise LabError('replicas를 3으로 선언해야 한다.')
        return cluster.wait('현재 배포 수렴', lambda: cluster.healthy(3))
    item('config', '프론트 구성', 30, servers)
    def service_check():
        # Keep this item independent of replica count mistakes for useful partial credit.
        _, pods = cluster.snapshot()
        if not pods or not all(ready(p) for p in pods):
            raise LabError('연결을 확인할 현재 revision의 Ready 서버가 필요하다.')
        if len(pods) < 2:
            raise LabError('분산을 관찰할 서버가 두 개 이상 필요하다.')
        connection(cluster.get('service/' + NAME), pods, [], check_endpoints=False)
        cluster.wait('Service·endpoint 연결', lambda: _connection(cluster, pods))
        cluster.traffic({p['metadata']['name'] for p in pods}, minimum=2)
        return pods
    item('service', '프론트 Service 연결', 30, service_check)
    item('backend', '프론트→백엔드 연결', 20, lambda: backend_check(cluster))
    if faults and passed.get('config') and passed.get('service'):
        item('recovery', '프론트 복구', 20, lambda: recovery_fault(cluster, cluster.healthy(3)))
    elif faults:
        print('[미실행 +0] 장애 검사: 서버 구성·Service 연결을 먼저 해결한다.')
    else:
        print('[미실행] 읽기 전용 검사: Pod 삭제·복구를 생략한다.')
    cluster.verify_resources()
    maximum = 100 if faults else 80
    print(f'점수: {points}/{maximum}' + (' (기본 검사, 전체 100점 중 복구 20점 미실행)' if not faults else ''))
    return 0 if points == maximum else 1


def _connection(cluster, pods, name=NAME):
    connection(cluster.get('service/' + name), pods, cluster.slices(name))
    return True


def advise_unchanged(cluster):
    # Compare declared resources, not Pod IDs/status changed by our own faults.
    resources = {}
    for name in (NAME, BACKEND_NAME):
        for kind in ('deployment', 'service'):
            resource = kind + '/' + name
            obj = cluster.get(resource, optional=True)
            resources[resource] = None if obj is None else {
                'uid': obj['metadata']['uid'], 'spec': obj['spec']}
    digest = hashlib.sha256(json.dumps(resources, sort_keys=True).encode()).hexdigest()
    key = hashlib.sha256((cluster.kubeconfig + CONTEXT + cluster.namespace).encode()).hexdigest()
    directory = ROOT / '.check-state'
    directory.mkdir(mode=0o700, exist_ok=True)
    path = directory / key
    try:
        previous = path.read_text().strip()
    except FileNotFoundError:
        previous = None
    if previous == digest:
        print('이전 check 이후 배포 설정이 바뀌지 않았습니다. 파일을 수정했다면 '
              f'kubectl -n {cluster.namespace} apply -f challenge/ 를 실행해주세요.', flush=True)
    temporary = path.with_suffix('.tmp')
    temporary.write_text(digest + '\n')
    temporary.replace(path)


def main():
    parser = argparse.ArgumentParser(description='과제 채점: 기본으로 장애 검사까지 수행한다.')
    parser.add_argument('--namespace', choices=['team-challenge'], required=True)
    parser.add_argument('--read-only', action='store_true', help='Pod 삭제 없이 프론트·Service·백엔드 연결을 검사한다.')
    parser.add_argument('--fault', '--faults', action='store_true', help=argparse.SUPPRESS)
    parser.add_argument('--timeout', type=int, default=120, help='전체 실행 제한 초 (10–600)')
    args = parser.parse_args()
    if not 10 <= args.timeout <= 600:
        parser.error('--timeout은 10–600초 범위다.')
    if args.read_only and args.fault:
        parser.error('--read-only와 --faults는 함께 사용할 수 없다.')
    signal.signal(signal.SIGINT, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    try:
        cluster = Cluster(args.namespace, args.timeout)
        cluster.validate()
        print(f'대상: {CONTEXT} / {cluster.namespace}', flush=True)
        with fault_lock(cluster):
            advise_unchanged(cluster)
            return grade(cluster, faults=not args.read_only)
    except KeyboardInterrupt:
        return 130
    except (LabError, OSError, ValueError) as e:
        print(f'실행 중단: {e}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
