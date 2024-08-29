import http from 'k6/http';
import { check, sleep } from 'k6';

export default function () {
  const res = http.get('https://test.k6.io');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(1);
}

export function handleSummary(data) {
  console.log("handleSummary called, data object:", JSON.stringify(data, null, 2));

  const checks = data.metrics.checks ? data.metrics.checks.values : {};
  const http_reqs = data.metrics.http_reqs ? data.metrics.http_reqs.values : {};

  console.log("checks:", checks);
  console.log("http_reqs:", JSON.stringify(http_reqs, null, 2));

  return {
    '/tmp/summary.json': JSON.stringify({
      checks: checks,
      http_reqs: http_reqs
    }, null, 2),
  };
}
