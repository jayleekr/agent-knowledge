#!/usr/bin/env python3
"""Python test runner for ops/analyze/ scripts."""
import subprocess, json, sys, os

BASE = os.path.dirname(os.path.abspath(__file__))
ANALYZE = os.path.join(BASE, '..', 'ops', 'analyze')
FIXTURES = os.path.join(BASE, 'fixtures')
METRICS = os.path.join(BASE, '..', 'metrics')

pass_count = 0
fail_count = 0
results = []

def run(*args):
    r = subprocess.run(list(args), capture_output=True, text=True)
    return r.returncode, r.stdout.strip(), r.stderr.strip()

def ok(name):
    global pass_count
    pass_count += 1
    print(f'  [PASS] {name}')
    results.append(('PASS', name))

def no(name, reason=''):
    global fail_count
    fail_count += 1
    msg = f'  [FAIL] {name}' + (f' — {reason}' if reason else '')
    print(msg)
    results.append(('FAIL', name, reason))

def test_json(name, *cmd, check=None):
    code, out, err = run(*cmd)
    if code != 0:
        no(name, f'exit={code} err={err[:80]}'); return
    try:
        d = json.loads(out)
    except Exception as e:
        no(name, f'bad JSON: {out[:60]}'); return
    if check:
        try:
            result = check(d)
            if result is False:
                no(name, 'check returned False'); return
        except AssertionError as e:
            no(name, str(e) or 'assertion failed'); return
        except Exception as e:
            no(name, str(e)); return
    ok(name)

def test_exit0(name, *cmd):
    code, out, err = run(*cmd)
    if code == 0: ok(name)
    else: no(name, f'exit={code} err={err[:60]}')

def test_nonzero(name, *cmd):
    code, out, err = run(*cmd)
    if code != 0: ok(name)
    else: no(name, f'expected non-zero, got 0. out={out[:40]}')

def has_keys(keys):
    def check(d):
        for k in keys:
            assert k in d, f'missing key: {k}'
    return check

# ── geo-check.sh ──────────────────────────────────────────────
print('\n[ geo-check.sh ]')
G = os.path.join(ANALYZE, 'geo-check.sh')

test_exit0('geo-check --help', 'bash', G, '--help')
test_json('geo-check --dry-run valid JSON', 'bash', G, '--dry-run')
test_json('geo-check --dry-run required keys', 'bash', G, '--dry-run',
    check=has_keys(['file', 'score', 'grade', 'findings', 'suggestions']))
test_json('geo-check --dry-run score is int', 'bash', G, '--dry-run',
    check=lambda d: None if isinstance(d['score'], int) else (_ for _ in ()).throw(AssertionError('score not int')))
test_json('geo-check --dry-run findings is list', 'bash', G, '--dry-run',
    check=lambda d: (None if isinstance(d['findings'], list) else exec('raise AssertionError("findings not list")')))
test_json('geo-check with sample-article.md', 'bash', G, os.path.join(FIXTURES, 'sample-article.md'))
test_json('geo-check article score 0-100', 'bash', G, os.path.join(FIXTURES, 'sample-article.md'),
    check=lambda d: (None if 0 <= d['score'] <= 100 else exec('raise AssertionError(f"score out of range: {d[chr(39)score{chr(39)}]}")')))
test_nonzero('geo-check fails missing file', 'bash', G, '/tmp/no_such_file_analyze_test')
test_nonzero('geo-check fails no args', 'bash', G)

# ── sentiment.sh ──────────────────────────────────────────────
print('\n[ sentiment.sh ]')
S = os.path.join(ANALYZE, 'sentiment.sh')

test_exit0('sentiment --help', 'bash', S, '--help')
test_json('sentiment --dry-run valid JSON', 'bash', S, '--dry-run')
test_json('sentiment --dry-run required keys', 'bash', S, '--dry-run',
    check=has_keys(['total', 'positive', 'negative', 'neutral', 'request', 'ratio']))
test_json('sentiment with sample-messages.json', 'bash', S, os.path.join(FIXTURES, 'sample-messages.json'))
test_json('sentiment total=10', 'bash', S, os.path.join(FIXTURES, 'sample-messages.json'),
    check=lambda d: (None if d['total'] == 10 else exec('raise AssertionError(f"total={d[chr(34)total{chr(34)}]}")')))
test_json('sentiment positive>=1', 'bash', S, os.path.join(FIXTURES, 'sample-messages.json'),
    check=lambda d: (None if d['positive'] >= 1 else exec('raise AssertionError(f"positive={d[chr(34)positive{chr(34)}]}")')))
test_json('sentiment negative>=1', 'bash', S, os.path.join(FIXTURES, 'sample-messages.json'),
    check=lambda d: (None if d['negative'] >= 1 else exec('raise AssertionError(f"negative={d[chr(34)negative{chr(34)}]}")')))
test_json('sentiment request>=1', 'bash', S, os.path.join(FIXTURES, 'sample-messages.json'),
    check=lambda d: (None if d['request'] >= 1 else exec('raise AssertionError(f"request={d[chr(34)request{chr(34)}]}")')))
test_json('sentiment counts sum to total', 'bash', S, os.path.join(FIXTURES, 'sample-messages.json'),
    check=lambda d: (None if d['positive']+d['negative']+d['neutral']+d['request']==d['total']
                     else exec('raise AssertionError("counts dont sum to total")')))
test_json('sentiment ratio has all keys', 'bash', S, os.path.join(FIXTURES, 'sample-messages.json'),
    check=lambda d: (None if all(k in d['ratio'] for k in ['positive','negative','neutral','request'])
                     else exec('raise AssertionError("ratio missing keys")')))
test_nonzero('sentiment fails missing file', 'bash', S, '/tmp/no_such_file_analyze_test')
test_nonzero('sentiment fails no args', 'bash', S)

# ── trend-compare.sh ──────────────────────────────────────────
print('\n[ trend-compare.sh ]')
T = os.path.join(ANALYZE, 'trend-compare.sh')

test_exit0('trend-compare --help', 'bash', T, '--help')
test_json('trend-compare --dry-run valid JSON', 'bash', T, '--dry-run')
test_json('trend-compare --dry-run is array', 'bash', T, '--dry-run',
    check=lambda d: (None if isinstance(d, list) else exec('raise AssertionError("not a list")')))
test_json('trend-compare with sample-metrics.json', 'bash', T, os.path.join(FIXTURES, 'sample-metrics.json'), '6')
test_json('trend-compare result is non-empty array', 'bash', T, os.path.join(FIXTURES, 'sample-metrics.json'), '6',
    check=lambda d: (None if isinstance(d, list) and len(d) > 0 else exec('raise AssertionError("empty or not list")')))
test_json('trend-compare required fields in each entry', 'bash', T, os.path.join(FIXTURES, 'sample-metrics.json'), '6',
    check=lambda d: (None if all(all(k in e for k in ['metric','current','avg_previous','trend','change_pct']) for e in d)
                     else exec('raise AssertionError("missing fields in entries")')))
test_json('trend-compare trend values valid', 'bash', T, os.path.join(FIXTURES, 'sample-metrics.json'), '6',
    check=lambda d: (None if all(e['trend'] in ['up','down','stable'] for e in d)
                     else exec('raise AssertionError(f"invalid trend: {[e[chr(39)trend{chr(39)}] for e in d]}")')))
test_json('trend-compare detects avg_score metric', 'bash', T, os.path.join(FIXTURES, 'sample-metrics.json'), '6',
    check=lambda d: (None if any(e['metric'] == 'avg_score' for e in d)
                     else exec('raise AssertionError("avg_score not found")')))
test_nonzero('trend-compare fails missing file', 'bash', T, '/tmp/no_such_file_analyze_test')
test_nonzero('trend-compare fails no args', 'bash', T)

# ── error-patterns.sh ─────────────────────────────────────────
print('\n[ error-patterns.sh ]')
E = os.path.join(ANALYZE, 'error-patterns.sh')

test_exit0('error-patterns --help', 'bash', E, '--help')
test_json('error-patterns --dry-run valid JSON', 'bash', E, '--dry-run')
test_json('error-patterns --dry-run required keys', 'bash', E, '--dry-run',
    check=has_keys(['total_errors', 'by_agent', 'top_patterns']))
test_json('error-patterns with sample-sessions.json', 'bash', E, os.path.join(FIXTURES, 'sample-sessions.json'))
test_json('error-patterns total_errors=10', 'bash', E, os.path.join(FIXTURES, 'sample-sessions.json'),
    check=lambda d: (None if d['total_errors'] == 10 else exec(f'raise AssertionError(f"total_errors={d[chr(34)total_errors{chr(34)}]}")')))
test_json('error-patterns by_agent has walter', 'bash', E, os.path.join(FIXTURES, 'sample-sessions.json'),
    check=lambda d: (None if 'walter' in d['by_agent'] else exec('raise AssertionError("walter not in by_agent")')))
test_json('error-patterns walter=5 errors', 'bash', E, os.path.join(FIXTURES, 'sample-sessions.json'),
    check=lambda d: (None if d['by_agent']['walter'] == 5 else exec(f'raise AssertionError(f"walter={d[chr(34)by_agent{chr(34)}][chr(34)walter{chr(34)}]}")')))
test_json('error-patterns top_patterns is list', 'bash', E, os.path.join(FIXTURES, 'sample-sessions.json'),
    check=lambda d: (None if isinstance(d['top_patterns'], list) else exec('raise AssertionError("not list")')))
test_json('error-patterns top is API timeout', 'bash', E, os.path.join(FIXTURES, 'sample-sessions.json'),
    check=lambda d: (None if len(d['top_patterns']) > 0 and d['top_patterns'][0]['message'] == 'API timeout'
                     else exec(f'raise AssertionError(f"top={d[chr(34)top_patterns{chr(34)}][:1]}")')))
test_json('error-patterns top_patterns has message+count', 'bash', E, os.path.join(FIXTURES, 'sample-sessions.json'),
    check=lambda d: (None if all('message' in p and 'count' in p for p in d['top_patterns'])
                     else exec('raise AssertionError("missing message/count")')))
test_nonzero('error-patterns fails missing file', 'bash', E, '/tmp/no_such_file_analyze_test')
test_nonzero('error-patterns fails no args', 'bash', E)

# ── agent-health.json ─────────────────────────────────────────
print('\n[ error-patterns + agent-health.json ]')
HEALTH = os.path.join(METRICS, 'agent-health.json')
test_json('error-patterns with agent-health.json', 'bash', E, HEALTH,
    check=has_keys(['total_errors', 'by_agent', 'top_patterns']))

# ── Summary ───────────────────────────────────────────────────
print(f'\n{"="*40}')
print(f'  Results: {pass_count} passed, {fail_count} failed')
print('='*40)
if fail_count == 0:
    print('ALL TESTS PASSED')
    sys.exit(0)
else:
    sys.exit(1)
