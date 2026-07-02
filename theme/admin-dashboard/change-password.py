#!/usr/bin/env python3
import http.server
import json
import subprocess
import base64
import signal

HTPASSWD = '/etc/angie/pass/.htpasswd'


def verify_auth(auth_header):
    if not auth_header or not auth_header.startswith('Basic '):
        return None
    try:
        decoded = base64.b64decode(auth_header[6:]).decode('utf-8')
        username, password = decoded.split(':', 1)
        result = subprocess.run(
            ['htpasswd', '-vi', HTPASSWD, username],
            input=password,
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            return username
    except Exception:
        pass
    return None


class Handler(http.server.BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Authorization, Content-Type')
        self.end_headers()

    def do_POST(self):
        try:
            auth = self.headers.get('Authorization', '')
            username = verify_auth(auth)
            if not username:
                self.send_json(401, {'error': 'Invalid credentials'})
                return

            content_length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(content_length).decode('utf-8'))
            new_password = body.get('new_password', '')

            if not new_password or len(new_password) < 3:
                self.send_json(400, {'error': 'New password must be at least 3 characters'})
                return

            result = subprocess.run(
                ['htpasswd', '-bi', HTPASSWD, username],
                input=new_password,
                capture_output=True, text=True, timeout=10
            )

            if result.returncode == 0:
                self.send_json(200, {'message': 'Password changed successfully'})
            else:
                err = result.stderr.strip() or 'Failed to update password'
                self.send_json(500, {'error': err})

        except json.JSONDecodeError:
            self.send_json(400, {'error': 'Invalid JSON'})
        except subprocess.TimeoutExpired:
            self.send_json(500, {'error': 'Password update timed out'})
        except Exception as e:
            self.send_json(500, {'error': str(e)})

    def send_json(self, status, data):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, *args):
        pass


if __name__ == '__main__':
    signal.signal(signal.SIGCHLD, signal.SIG_IGN)
    server = http.server.HTTPServer(('127.0.0.1', 9090), Handler)
    server.serve_forever()
