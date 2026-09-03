#!/usr/bin/env python3
import http.server
import json
import os
import socket
import struct
import subprocess
import sys
import threading
import time
import urllib.request

class CustomHTTPHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def guess_type(self, path):
        if path.endswith('.wasm'):
            return 'application/wasm'
        if path.endswith('.js') or path.endswith('.mjs'):
            return 'application/javascript'
        return super().guess_type(path)

    def log_message(self, format, *args):
        pass


def start_server(web_dir, port):
    handler = lambda *args, **kwargs: CustomHTTPHandler(*args, directory=web_dir, **kwargs)
    server = http.server.HTTPServer(('127.0.0.1', port), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def find_free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]


class SimpleWebSocket:
    def __init__(self, ws_url):
        parts = ws_url.replace('ws://', '').split('/', 1)
        host, port = parts[0].split(':')
        self.path = '/' + (parts[1] if len(parts) > 1 else '')
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((host, int(port)))
        self._handshake(host, port)

    def _handshake(self, host, port):
        key = "dGhlIHNhbXBsZSBub25jZQ=="
        req = (
            f"GET {self.path} HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            f"Upgrade: websocket\r\n"
            f"Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            f"Sec-WebSocket-Version: 13\r\n\r\n"
        )
        self.sock.sendall(req.encode())
        res = b""
        while b"\r\n\r\n" not in res:
            chunk = self.sock.recv(1024)
            if not chunk:
                break
            res += chunk
        res_str = res.decode('utf-8', errors='ignore')
        if "101" not in res_str:
            raise Exception(f"WebSocket handshake failed: {res_str}")

    def send_json(self, obj):
        data = json.dumps(obj).encode('utf-8')
        length = len(data)
        frame = bytearray([0x81])
        mask = [0x12, 0x34, 0x56, 0x78]
        if length <= 125:
            frame.append(0x80 | length)
        elif length <= 65535:
            frame.append(0x80 | 126)
            frame.extend(struct.pack('!H', length))
        else:
            frame.append(0x80 | 127)
            frame.extend(struct.pack('!Q', length))
        frame.extend(mask)
        masked_data = bytearray(b ^ mask[i % 4] for i, b in enumerate(data))
        frame.extend(masked_data)
        self.sock.sendall(frame)

    def _recv_exact(self, n):
        data = bytearray()
        while len(data) < n:
            chunk = self.sock.recv(n - len(data))
            if not chunk:
                raise EOFError("Socket closed")
            data.extend(chunk)
        return data

    def recv_json(self, timeout=1.0):
        self.sock.settimeout(timeout)
        try:
            head = self._recv_exact(2)
            b1, b2 = head[0], head[1]
            opcode = b1 & 0x0F
            is_masked = bool(b2 & 0x80)
            payload_len = b2 & 0x7F
            if payload_len == 126:
                payload_len = struct.unpack('!H', self._recv_exact(2))[0]
            elif payload_len == 127:
                payload_len = struct.unpack('!Q', self._recv_exact(8))[0]
            mask = self._recv_exact(4) if is_masked else None
            data = self._recv_exact(payload_len)
            if is_masked:
                data = bytearray(b ^ mask[i % 4] for i, b in enumerate(data))
            return json.loads(data.decode('utf-8'))
        except (socket.timeout, EOFError):
            return None


def run_test(web_dir, test_name):
    print(f"\n==================================================")
    print(f"Running Web Runtime Verification: {test_name}")
    print(f"Directory: {web_dir}")
    print(f"==================================================")

    http_port = find_free_port()
    cdp_port = find_free_port()

    server = start_server(web_dir, http_port)
    print(f"HTTP Server started on http://127.0.0.1:{http_port}")

    chrome_cmd = [
        os.environ.get('CHROME_EXECUTABLE', '/usr/sbin/chromium'),
        '--headless=new',
        f'--remote-debugging-port={cdp_port}',
        '--disable-extensions',
        '--no-sandbox',
        '--disable-gpu',
        '--disable-dev-shm-usage',
        'about:blank',
    ]

    proc = subprocess.Popen(chrome_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        ws_url = None
        for _ in range(30):
            time.sleep(0.2)
            try:
                with urllib.request.urlopen(f'http://127.0.0.1:{cdp_port}/json/list', timeout=1) as resp:
                    tabs = json.loads(resp.read().decode())
                    for tab in tabs:
                        if tab.get('type') == 'page':
                            ws_url = tab.get('webSocketDebuggerUrl')
                            break
                    if ws_url:
                        break
            except Exception:
                pass

        if not ws_url:
            raise Exception("Could not connect to Chrome DevTools Protocol")

        print(f"Connected to Chrome CDP page at {ws_url}")
        ws = SimpleWebSocket(ws_url)
        ws.send_json({"id": 1, "method": "Page.enable"})
        ws.send_json({"id": 2, "method": "Runtime.enable"})
        ws.send_json({"id": 3, "method": "Console.enable"})
        ws.send_json({"id": 4, "method": "Log.enable"})

        # Navigate to target page
        target_url = f"http://127.0.0.1:{http_port}/"
        print(f"Navigating to {target_url}...")
        ws.send_json({"id": 5, "method": "Page.navigate", "params": {"url": target_url}})

        logs = []
        errors = []
        sweph_results = {}
        success = False

        start_time = time.time()
        timeout = 30.0

        while time.time() - start_time < timeout:
            msg = ws.recv_json(timeout=0.5)
            if not msg:
                continue

            method = msg.get('method', '')
            if method == 'Runtime.consoleAPICalled':
                params = msg.get('params', {})
                args = params.get('args', [])
                text = ' '.join(str(a.get('value', '')) for a in args)
                logs.append(text)
                print(f"[Browser Console] {text}")
                if '[SWEPH_TEST]' in text:
                    parts = text.split('[SWEPH_TEST]')[-1].strip().split(':', 1)
                    if len(parts) == 2:
                        key = parts[0].strip()
                        val = parts[1].strip()
                        sweph_results[key] = val
                    elif 'SUCCESS' in text:
                        success = True
                        break
            elif method == 'Console.messageAdded':
                msg_obj = msg.get('params', {}).get('message', {})
                text = msg_obj.get('text', '')
                logs.append(text)
                print(f"[Console Message] {text}")
                if '[SWEPH_TEST]' in text:
                    parts = text.split('[SWEPH_TEST]')[-1].strip().split(':', 1)
                    if len(parts) == 2:
                        key = parts[0].strip()
                        val = parts[1].strip()
                        sweph_results[key] = val
                    elif 'SUCCESS' in text:
                        success = True
                        break
            elif method == 'Log.entryAdded':
                entry = msg.get('params', {}).get('entry', {})
                text = entry.get('text', '')
                logs.append(text)
                print(f"[Log Entry] {text}")
            elif method == 'Runtime.exceptionThrown':
                desc = msg.get('params', {}).get('exceptionDetails', {}).get('exception', {}).get('description', '')
                errors.append(desc)
                print(f"[Browser ERROR] {desc}")

        print("\n--- Validation Results ---")
        print(f"Captured logs: {len(logs)}")
        print(f"Sweph results: {json.dumps(sweph_results, indent=2)}")

        if errors:
            print(f"FAILED with {len(errors)} runtime error(s)!")
            for err in errors:
                print(f"  Error: {err}")
            return False

        if not success or not sweph_results:
            print("FAILED: Sweph initialization and calculations did not complete successfully.")
            return False

        version = sweph_results.get('version', '')
        assert version.startswith('2.10'), f"Invalid version: {version}"

        moon = sweph_results.get('moon', '')
        assert 'lat=' in moon and 'lon=' in moon, f"Invalid moon coords: {moon}"

        star = sweph_results.get('star', '')
        assert star and float(star) > 0, f"Invalid star distance: {star}"

        asteroid = sweph_results.get('asteroid', '')
        assert asteroid == 'Psyche', f"Unexpected asteroid name: {asteroid}"

        chiron = sweph_results.get('chiron', '')
        assert chiron, f"Missing Chiron coords: {chiron}"

        print(f"\n>>> SUCCESS: {test_name} verified cleanly in headless browser! <<<\n")
        return True

    finally:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except Exception:
            proc.kill()
        server.shutdown()


def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    example_web_dir = os.path.join(repo_root, 'example', 'build', 'web')

    mode = sys.argv[1] if len(sys.argv) > 1 else 'all'

    ok = True
    if mode in ('all', 'normal'):
        print("Building normal Flutter Web (dart2js)...")
        subprocess.check_call(['flutter', 'build', 'web'], cwd=os.path.join(repo_root, 'example'))
        if not run_test(example_web_dir, "Normal Flutter Web (dart2js)"):
            ok = False

    if mode in ('all', 'wasm'):
        print("Building Flutter Web with --wasm (dart2wasm)...")
        subprocess.check_call(['flutter', 'build', 'web', '--wasm'], cwd=os.path.join(repo_root, 'example'))
        if not run_test(example_web_dir, "Flutter Web with --wasm (dart2wasm)"):
            ok = False

    if not ok:
        sys.exit(1)


if __name__ == '__main__':
    main()
