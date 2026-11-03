"""Presenter environment initialization and read-only observation."""

import argparse
import signal
import sys

from lab import (Cluster, CONTEXT, IMAGE, NAME, ROOT, LabError, fault_lock, interrupted)


def apply_solution(cluster):
    ns = {'apiVersion': 'v1', 'kind': 'Namespace', 'metadata': {'name': cluster.namespace}}
    cluster.run('apply', '-f', '-', data=ns)
    cluster.run('apply', '-f', str(ROOT / 'fixtures/solution'))
    cluster.run('apply', '-f', str(ROOT / 'client.yaml'))
    for pod in cluster.snapshot()[1]:
        if (pod.get('status', {}).get('phase') == 'Running'
                and any(c['image'] == IMAGE for c in pod['spec']['containers'])):
            cluster.mark(pod, False)
    return cluster.wait('시연 서버 준비', lambda: cluster.healthy(3))


def demo(cluster, action):
    with fault_lock(cluster):
        if action in ('prepare', 'reset'):
            # Recreating the namespace removes every namespaced resource, not
            # only the resource kinds covered by `kubectl delete all`.
            print('team-demo의 모든 리소스와 PVC를 삭제하고 정상 예제로 초기화한다.', flush=True)
            cluster.run('delete', 'namespace', cluster.namespace, '--ignore-not-found',
                        '--wait=true', '--timeout=60s', timeout=65)
            apply_solution(cluster)
            cluster.run('config', 'set-context', CONTEXT, '--namespace=' + cluster.namespace)
            cluster.run('wait', '--for=condition=Ready', 'pod/client', '--timeout=60s', timeout=65)
            print('기본 namespace: team-demo (로컬 실습 kubeconfig).', flush=True)
            print('정상 시연 상태가 준비되었다. 이제 직접 kubectl 명령을 입력한다.')
        # No experiment, fault injection or automatic recovery occurs here.
        print(cluster.run('get', 'deployment,replicaset,pod,service', '-o', 'wide').stdout)
        print(cluster.run('get', 'endpointslices', '-l',
                          'kubernetes.io/service-name=' + NAME, '-o', 'yaml').stdout)


def main():
    parser = argparse.ArgumentParser(description='발표자 환경 초기화와 상태 조회')
    parser.add_argument('action', choices=['prepare', 'reset', 'show'],
                        help='prepare/reset: namespace 전체 초기화, show: 상태 조회만 수행한다.')
    parser.add_argument('--timeout', type=int, default=120, help='전체 실행 제한 초 (10–600)')
    args = parser.parse_args()
    if not 10 <= args.timeout <= 600:
        parser.error('--timeout은 10–600초 범위다.')
    signal.signal(signal.SIGINT, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    try:
        cluster = Cluster('team-demo', args.timeout)
        cluster.validate()
        print(f'대상: {CONTEXT} / {cluster.namespace}', flush=True)
        demo(cluster, args.action)
        return 0
    except KeyboardInterrupt:
        return 130
    except (LabError, OSError, ValueError) as e:
        print(f'실행 중단: {e}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
