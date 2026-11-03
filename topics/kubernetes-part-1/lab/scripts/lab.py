"""Local teaching tools. Only kubectl and Python's standard library are required."""

import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
CONTEXT = 'colima-infra-study' if sys.platform == 'darwin' else 'k3d-infra-study'
IMAGE = 'team-server:v1'
NAME = 'team-server'
BACKEND_NAME = 'team-backend'
BACKEND_MESSAGE = 'Hello from backend!'


class LabError(Exception):
    pass


class WaitTimeout(LabError):
    pass


class RetrySample(LabError):
    pass


def ready(pod):
    return not pod['metadata'].get('deletionTimestamp') and any(
        c['type'] == 'Ready' and c['status'] == 'True'
        for c in pod.get('status', {}).get('conditions', []))


def owned(obj, uid):
    return any(o.get('uid') == uid and o.get('controller') is True
               for o in obj['metadata'].get('ownerReferences', []))


def current_pods(deployment, replicasets, pods):
    revision = deployment['metadata'].get('annotations', {}).get(
        'deployment.kubernetes.io/revision')
    owners = {r['metadata']['uid'] for r in replicasets
              if revision and owned(r, deployment['metadata']['uid'])
              and r['metadata'].get('annotations', {}).get(
                  'deployment.kubernetes.io/revision') == revision}
    return [p for p in pods if any(owned(p, uid) for uid in owners)
            and not p['metadata'].get('deletionTimestamp')]


def port_number(pod, port):
    if isinstance(port, int):
        return port
    for c in pod['spec']['containers']:
        for p in c.get('ports', []):
            if p.get('name') == port:
                return p['containerPort']
    return None


def server_container(pod):
    servers = [c for c in pod['spec']['containers'] if c['image'] == IMAGE]
    if len(servers) != 1:
        raise LabError(f'{pod["metadata"]["name"]}: 지정 서버 이미지가 필요하다.')
    return servers[0]


def environment(container):
    return {e['name']: e['value'] for e in container.get('env', []) if 'value' in e}


def resource_signature(obj):
    return None if obj is None else (obj['metadata']['uid'], json.dumps(obj['spec'], sort_keys=True))


def configuration(deployment, pods, count=3, role='frontend'):
    status = deployment.get('status', {})
    if deployment['spec'].get('replicas', 1) != count:
        raise LabError(f'replicas를 {count}으로 선언해야 한다.')
    if status.get('observedGeneration', 0) < deployment['metadata']['generation']:
        raise LabError('최신 Deployment 세대가 아직 관찰되지 않았다.')
    if (len(pods) != count or not all(ready(p) for p in pods)
            or status.get('updatedReplicas', 0) != count
            or status.get('readyReplicas', 0) != count):
        raise LabError(f'현재 revision의 서버 {count}개가 모두 Ready가 되어야 한다.')
    for p in pods:
        if environment(server_container(p)).get('SERVER_ROLE', 'frontend') != role:
            raise LabError(f'{p["metadata"]["name"]}: SERVER_ROLE={role}로 실행해야 한다.')


def endpoint_uids(slices):
    result = set()
    for s in slices:
        if not any(p.get('port') == 8080 and p.get('protocol', 'TCP') == 'TCP'
                   for p in s.get('ports', [])):
            continue
        for e in s.get('endpoints', []):
            if e.get('conditions', {}).get('ready') is True:
                ref = e.get('targetRef', {})
                if ref.get('kind') == 'Pod':
                    result.add(ref.get('uid'))
    return result


def connection(service, pods, slices, check_endpoints=True):
    if service['spec'].get('type', 'ClusterIP') != 'ClusterIP':
        raise LabError('Service는 기본 ClusterIP를 사용해야 한다.')
    if service['spec'].get('publishNotReadyAddresses', False):
        raise LabError('준비되지 않은 주소를 게시하지 않아야 한다.')
    selector = service['spec'].get('selector', {})
    if not selector or not all(all(p['metadata'].get('labels', {}).get(k) == v
                                  for k, v in selector.items()) for p in pods):
        raise LabError('Service selector와 서버 Pod label이 일치하지 않는다.')
    ports = [p for p in service['spec'].get('ports', [])
             if p['port'] == 80 and p.get('protocol', 'TCP') == 'TCP']
    if not ports or any(port_number(p, ports[0].get('targetPort', 80)) != 8080
                        for p in pods):
        raise LabError('Service 80번 포트가 서버 8080번 포트로 연결되어야 한다.')
    if check_endpoints and endpoint_uids(slices) != {p['metadata']['uid'] for p in pods}:
        raise LabError('EndpointSlice의 준비된 대상이 현재 서버 집합과 다르다.')


class Cluster:
    def __init__(self, namespace, timeout=120):
        self.namespace = namespace
        self.deadline = time.monotonic() + timeout
        self.fingerprints = {}
        self.kubeconfig = str(Path(os.environ.get('KUBECONFIG', ROOT / '.kubeconfig.local')).resolve())
        if not Path(self.kubeconfig).is_file():
            raise LabError('로컬 kubeconfig가 없다. KUBECONFIG와 클러스터 준비를 확인한다.')

    def run(self, *args, data=None, timeout=15, allow_error=False):
        left = self.deadline - time.monotonic()
        if left <= 0:
            raise WaitTimeout('전체 실행 제한 시간을 초과했다. 상태를 확인하고 다시 검사한다.')
        cmd = ['kubectl', '--kubeconfig', self.kubeconfig, '--context', CONTEXT,
               '--namespace', self.namespace, '--request-timeout=10s', *args]
        try:
            p = subprocess.run(cmd, input=None if data is None else json.dumps(data),
                               text=True, capture_output=True, timeout=min(timeout, left))
        except subprocess.TimeoutExpired as e:
            raise WaitTimeout('kubectl 응답 제한 시간을 초과했다.') from e
        except FileNotFoundError as e:
            raise LabError('kubectl이 없다. lab/의 nix develop 환경에서 실행한다.') from e
        if p.returncode and not allow_error:
            raise LabError(p.stderr.strip() or p.stdout.strip() or 'kubectl 실행 실패')
        return p

    def get(self, resource, optional=False):
        p = self.run('get', resource, '-o', 'json', allow_error=optional)
        if p.returncode:
            if not (optional and '(NotFound)' in p.stderr):
                raise LabError(p.stderr.strip())
            obj = None
        else:
            obj = json.loads(p.stdout)
        if resource in self.fingerprints and resource_signature(obj) != self.fingerprints[resource]:
            raise LabError(f'검사 중 {resource} 설정이 변경되었다. 적용이 끝난 뒤 다시 검사한다.')
        return obj

    def pin_resources(self):
        # Ignore controller status changes and Pod replacements made by this grader.
        for name in (NAME, BACKEND_NAME):
            for kind in ('deployment', 'service'):
                resource = kind + '/' + name
                self.fingerprints[resource] = resource_signature(self.get(resource, optional=True))

    def verify_resources(self):
        for resource in self.fingerprints:
            self.get(resource, optional=True)

    def validate(self):
        cfg = json.loads(self.run('config', 'view', '-o', 'json').stdout)
        if cfg.get('current-context') != CONTEXT:
            raise LabError(f'현재 context가 {CONTEXT}가 아니다. 다른 클러스터에서는 실행하지 않는다.')
        contexts = {c['name']: c['context'] for c in cfg['contexts']}
        clusters = {c['name']: c['cluster'] for c in cfg['clusters']}
        target = contexts.get(CONTEXT, {}).get('cluster')
        server = clusters.get(target, {}).get('server', '')
        # Both lab backends expose a local API endpoint.
        if target != CONTEXT or urlparse(server).hostname not in ('127.0.0.1', '0.0.0.0', 'localhost', '::1'):
            raise LabError('실습용 로컬 Kubernetes API 주소가 아니다.')
        if self.namespace not in ('team-challenge', 'team-demo'):
            raise LabError('허용된 실습 namespace가 아니다.')

    def snapshot(self, name=NAME):
        d = self.get('deployment/' + name)
        rs = self.get('replicasets')['items']
        pods = self.get('pods')['items']
        return d, current_pods(d, rs, pods)

    def slices(self, name=NAME):
        return json.loads(self.run('get', 'endpointslices', '-l',
                                  'kubernetes.io/service-name=' + name, '-o', 'json').stdout)['items']

    def wait(self, describe, check):
        last = ''
        while time.monotonic() < self.deadline:
            try:
                result = check()
                if result:
                    return result
            except WaitTimeout:
                raise
            except LabError as e:
                last = str(e)
            time.sleep(1)
        raise WaitTimeout(f'{describe}: 대기 시간 초과. {last}')

    def healthy(self, count, name=NAME):
        d, pods = self.snapshot(name)
        configuration(d, pods, count, role='backend' if name == BACKEND_NAME else 'frontend')
        return pods

    def identity(self, pod):
        current = self.get('pod/' + pod['metadata']['name'], optional=True)
        if (current and current['metadata']['uid'] == pod['metadata']['uid']
                and current['metadata'].get('ownerReferences') == pod['metadata'].get('ownerReferences')):
            return current
        return None

    def delete(self, pod):
        # API UID precondition closes the get/delete name-reuse race.
        self.verify_resources()
        self.snapshot()
        if not self.identity(pod):
            raise LabError('삭제할 Pod가 교체되거나 소유 관계가 변경되었다.')
        name = pod['metadata']['name']
        self.run('delete', '--raw', f'/api/v1/namespaces/{self.namespace}/pods/{name}',
                 '-f', '-', data={'apiVersion': 'v1', 'kind': 'DeleteOptions',
                                 'preconditions': {'uid': pod['metadata']['uid']}})

    def traffic(self, expected, minimum=1, path='/', backend=None):
        if path not in ('/', '/api'):
            raise LabError('지원하지 않는 검사 경로다.')
        client = self.get('pod/client')
        if not ready(client):
            raise LabError('내부 client Pod가 아직 Ready가 아니다.')
        seen = set()
        for _ in range(3):
            # Each curl process opens a fresh connection; one kubectl exec per batch.
            script = ('i=0; while [ "$i" -lt 12 ]; do '
                      'curl -fsS --http1.1 -H "Connection: close" --connect-timeout 1 '
                      f'--max-time 2 http://team-server{path} || exit 1; '
                      'printf "\\n__RESPONSE_END__\\n"; i=$((i+1)); done')
            output = self.run('exec', 'client', '--', 'sh', '-c', script, timeout=30).stdout
            bodies = output.split('__RESPONSE_END__')[:-1]
            if len(bodies) != 12:
                raise LabError('HTTP 응답을 끝까지 읽지 못했다.')
            for body in bodies:
                fields = dict(line.split(': ', 1) for line in body.strip().splitlines() if ': ' in line)
                name = fields.get('pod')
                if name not in expected:
                    raise LabError(f'예상 서버 외 응답이다: {name!r}')
                if not {'message', 'revision', 'pod'} <= fields.keys():
                    raise LabError('실습 서버의 응답 형식과 다르다.')
                if backend and any(fields.get(key) != value for key, value in backend.items()):
                    raise LabError('프론트 응답의 백엔드 메시지·Pod 이름·UID가 실제 백엔드와 다르다.')
                seen.add(name)
            if len(seen) >= minimum:
                return seen
        raise RetrySample('재검사 필요: 준비된 endpoint는 있으나 복수 서버 응답을 관찰하지 못했다.')


@contextlib.contextmanager
def fault_lock(cluster):
    key = hashlib.sha256((cluster.kubeconfig + CONTEXT + cluster.namespace).encode()).hexdigest()[:20]
    directory = Path(tempfile.gettempdir()) / f'k8s-study-{os.getuid()}'
    directory.mkdir(mode=0o700, exist_ok=True)
    with (directory / key).open('a') as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as e:
            raise LabError('같은 실습 namespace의 다른 검사가 이미 실행 중이다.') from e
        yield


def interrupted(_signum, _frame):
    # Ignore repeated signals while the process unwinds.
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    raise KeyboardInterrupt

