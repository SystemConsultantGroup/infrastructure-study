import os
import signal
import threading
import time
from http.client import HTTPException
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import URLError
from urllib.request import ProxyHandler, build_opener
from urllib.parse import urlsplit

NOTE = Path('/data/note.txt')
BACKEND_MESSAGE = 'Hello from backend!'


def role():
    return os.getenv('SERVER_ROLE', 'frontend')


def frontend_body():
    return (f"message: {os.getenv('MESSAGE', 'Hello, Kubernetes!')}\n"
            f"revision: {os.getenv('REVISION', 'v1')}\n"
            f"pod: {os.getenv('POD_NAME', 'local')}\n")


def fetch_backend():
    # Service traffic stays inside the cluster, regardless of host proxy settings.
    address = os.environ['BACKEND_URL']
    if urlsplit(address).scheme != 'http':
        raise ValueError('backend URL must use HTTP')
    with build_opener(ProxyHandler({})).open(address, timeout=1) as response:
        if response.status != 200:
            raise ValueError('backend returned a non-200 response')
        data = response.read(4097)
    if len(data) > 4096:
        raise ValueError('backend response is too large')
    fields = {}
    for line in data.decode('utf-8').splitlines():
        key, separator, value = line.partition(': ')
        if not separator or key in fields or not value:
            raise ValueError('invalid backend response')
        fields[key] = value
    if not {'message', 'pod', 'uid'} <= fields.keys():
        raise ValueError('incomplete backend response')
    return fields


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, body):
        data = body.encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if role() == 'frontend' and self.path in ('/', '/api'):
            time.sleep(0.1)
        if self.path == '/':
            if role() == 'backend':
                self.respond(200, f"message: {BACKEND_MESSAGE}\npod: {os.getenv('POD_NAME', 'local')}\n"
                                 f"uid: {os.getenv('POD_UID', 'local')}\n")
            else:
                self.respond(200, frontend_body())
        elif self.path == '/api' and role() == 'frontend':
            try:
                backend = fetch_backend()
            except (KeyError, ValueError, UnicodeError, OSError, URLError, HTTPException):
                self.respond(502, 'backend unavailable or invalid response\n')
                return
            self.respond(200, frontend_body() + f"backend_message: {backend['message']}\n"
                         f"backend_pod: {backend['pod']}\nbackend_uid: {backend['uid']}\n")
        elif self.path == '/ready':
            ready = not Path('/tmp/not-ready').exists()
            self.respond(200 if ready else 503, 'ready\n' if ready else 'not ready\n')
        elif self.path == '/note':
            try:
                self.respond(200, NOTE.read_text(encoding='utf-8'))
            except FileNotFoundError:
                self.respond(404, 'no note\n')
        else:
            self.respond(404, 'not found\n')

    def do_PUT(self):
        if self.path != '/note':
            self.respond(404, 'not found\n')
            return
        try:
            size = int(self.headers.get('Content-Length', '-1'))
        except ValueError:
            size = -1
        if not 0 <= size <= 4096:
            self.respond(400, 'Content-Length must be between 0 and 4096 bytes\n')
            return
        try:
            note = self.rfile.read(size).decode('utf-8')
            NOTE.write_text(note, encoding='utf-8')
        except (UnicodeDecodeError, OSError):
            self.respond(400, 'could not write UTF-8 note to /data\n')
            return
        self.respond(200, 'saved\n')


def main():
    if role() not in ('frontend', 'backend'):
        raise ValueError('SERVER_ROLE must be frontend or backend')
    server = ThreadingHTTPServer(('0.0.0.0', 8080), Handler)
    server.daemon_threads = False
    signal.signal(signal.SIGTERM, lambda *_: threading.Thread(target=server.shutdown).start())
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
