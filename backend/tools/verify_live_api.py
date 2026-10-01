#!/usr/bin/env python3
"""Read-only post-deployment checks. Does not authenticate, charge or mutate data."""
import json
import sys
import urllib.error
import urllib.request

BASE = 'https://nounupdate.com/api/v1'
CHECKS = {'/health': lambda d: d.get('status') == 'ok', '/services': lambda d: isinstance(d.get('items'), list), '/posts/news': lambda d: isinstance(d.get('items'), list), '/materials': lambda d: isinstance(d.get('items'), list), '/exam-summaries': lambda d: isinstance(d.get('items'), list), '/calendar': lambda d: isinstance(d.get('events'), list)}
failed = False
for path, validate in CHECKS.items():
    try:
        request = urllib.request.Request(BASE + path, headers={'Accept': 'application/json', 'User-Agent': 'NOUNUpdate-Readiness/0.4'})
        with urllib.request.urlopen(request, timeout=20) as response:
            if response.geturl() != BASE + path:
                raise ValueError('unexpected redirect')
            if 'application/json' not in response.headers.get('Content-Type', ''):
                raise ValueError('expected JSON')
            payload = json.loads(response.read(2_000_001))
            if not isinstance(payload, dict) or not isinstance(payload.get('data'), dict) or not validate(payload['data']):
                raise ValueError('unexpected response structure')
        print('PASS', path)
    except urllib.error.HTTPError as error:
        print('FAIL', path, 'HTTP', error.code)
        failed = True
    except Exception as error:
        print('FAIL', path, type(error).__name__)
        failed = True
sys.exit(1 if failed else 0)
