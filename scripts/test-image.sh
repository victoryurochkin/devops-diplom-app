#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:?Usage: $0 IMAGE}"
TEST_CONTAINER=""

cleanup() {
  if [ -n "$TEST_CONTAINER" ]; then
    docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

docker run --rm "$IMAGE" -t

TEST_CONTAINER="$(docker run -d \
  -p 127.0.0.1::8080 \
  "$IMAGE")"

TEST_ADDRESS="$(docker port "$TEST_CONTAINER" 8080/tcp)"
READY=false

for attempt in {1..30}; do
  if curl --noproxy '*' --fail --silent \
    --connect-timeout 1 --max-time 2 \
    "http://$TEST_ADDRESS/healthz" >/dev/null
  then
    READY=true
    break
  fi
  sleep 1
done

if [ "$READY" != true ]; then
  docker logs "$TEST_CONTAINER"
  exit 1
fi

PAGE="$(curl --noproxy '*' --fail --silent --show-error \
  --max-time 10 "http://$TEST_ADDRESS/")"
[[ "$PAGE" == *"DEVOPS DIPLOMA"* ]]
[[ "$PAGE" == *"Виктор Юрочкин"* ]]

HEALTH="$(curl --noproxy '*' --fail --silent --show-error \
  --max-time 10 "http://$TEST_ADDRESS/healthz")"
[[ "$HEALTH" == "ok" ]]

printf 'OK: nginx configuration, HTTP page, content and healthz\n'
