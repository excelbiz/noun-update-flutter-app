"""Exercise the app's exported CSS/JS in a local HTTPS browser fixture.

All mapped hosts resolve to this local fixture server. No live site is contacted.
"""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
import shutil
import ssl
import subprocess
import tempfile
import threading

root = Path(tempfile.gettempdir()) / 'nu-web-skin-fixtures'
cases = json.loads((root / 'index.json').read_text())
chrome = next((shutil.which(name) for name in ('google-chrome', 'chromium', 'chromium-browser') if shutil.which(name)), None)
if not chrome:
    raise RuntimeError('A Chromium browser is required for web skin verification')

class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass

with tempfile.TemporaryDirectory(prefix='nu-web-skin-browser-') as tmp:
    cert, key = Path(tmp) / 'cert.pem', Path(tmp) / 'key.pem'
    subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', str(key), '-out', str(cert), '-days', '1', '-subj', '/CN=nounupdate.com'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Handler, directory=str(root)))
    tls = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    tls.load_cert_chain(cert, key)
    server.socket = tls.wrap_socket(server.socket, server_side=True)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    port = server.server_address[1]
    hosts = {'nounupdate.com', 'nounupdate.com.attacker.test', 'paystack.test'}
    rules = ','.join(f'MAP {host} 127.0.0.1' for host in sorted(hosts))
    screenshots = Path('screenshots')
    screenshots.mkdir(exist_ok=True)
    try:
        for case in cases:
            host = case.get('host', 'nounupdate.com')
            flags = [chrome, '--headless', '--no-sandbox', '--disable-gpu', '--no-proxy-server', '--disable-background-networking', '--ignore-certificate-errors', f'--host-resolver-rules={rules}', '--virtual-time-budget=3000', '--window-size=390,844', '--force-device-scale-factor=2', f'--user-data-dir={tmp}/profile', '--dump-dom']
            if (case.get('skin'), case.get('brightness')) in {('elegantEditorial', 'light'), ('boldPremium', 'light'), ('futureTech', 'dark'), ('futureTech', 'light')}:
                target = screenshots / f"web-fixture-{case['skin']}-{case['brightness']}.png"
                flags.append(f'--screenshot={target.resolve()}')
            result = subprocess.run(flags + [f"https://{host}:{port}/{case['file']}"], capture_output=True, text=True, timeout=30)
            if result.returncode or 'data-theme-test="PASS"' not in result.stdout:
                # The actual page contains embedded font data; never dump it to logs.
                import re
                failure = re.search(r'data-theme-test="([^"]+)"', result.stdout)
                raise RuntimeError(f"{case['file']} on {host}: {failure.group(1) if failure else 'browser did not finish'}; {result.stderr[-500:]}")
            print(f"PASS: {case['file']} ({host})")
        print(f'All {len(cases)} browser skin checks passed; form values/actions, validation, destructive styling, frames and origin boundaries retained.')
    finally:
        server.shutdown()
