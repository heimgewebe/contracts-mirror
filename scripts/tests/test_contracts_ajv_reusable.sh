#!/bin/bash
set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Mock root and setup
mkdir -p "$TMP/_contracts/json/nested"
touch "$TMP/_contracts/json/root.schema.json"
touch "$TMP/_contracts/json/nested/nested.schema.json"

echo "== Schema Discovery =="
ROOT="$TMP/_contracts/json"
SCHEMA_PATTERN="**/*.schema.json"
name_pattern="${SCHEMA_PATTERN##*/}"
if [[ -z "$name_pattern" || "$name_pattern" == "*" ]]; then
  name_pattern="*.schema.json"
fi

mapfile -t schemas < <(find "$ROOT" -type f -name "$name_pattern" -print | sort || true)
if (( ${#schemas[@]} != 2 )); then
  echo "FAIL: Expected 2 schemas, found ${#schemas[@]}"
  exit 1
fi
echo "Schemas found: ${#schemas[@]}"

echo "== Fixture Discovery =="
mkdir -p "$TMP/fixtures/nested"
touch "$TMP/fixtures/root.json"
touch "$TMP/fixtures/nested/nested.jsonl"
touch "$TMP/fixtures/empty.jsonl"

cd "$TMP"
shopt -s nullglob globstar
fixtures=( fixtures/**/*.jsonl )
if (( ${#fixtures[@]} == 0 )); then
  fixtures=( fixtures/**/*.{jsonl,json} )
fi
if (( ${#fixtures[@]} != 2 )); then
  echo "FAIL: Expected 2 fixtures, found ${#fixtures[@]}"
  exit 1
fi
echo "Fixtures found: ${#fixtures[@]}"

echo "== Counter increment test =="
count=0
((count += 1))
if (( count != 1 )); then
  echo "FAIL: Counter not incremented safely."
  exit 1
fi
echo "Counter safe."

echo "== JSONL Processing =="
echo '{"valid": 1}' > "$TMP/fixtures/test.jsonl"
echo "" >> "$TMP/fixtures/test.jsonl"
echo '{"valid": 2}' >> "$TMP/fixtures/test.jsonl"

line_num=0
valid_lines=0
while IFS= read -r line || [[ -n "$line" ]]; do
  ((line_num += 1))
  [[ -z "${line// }" ]] && continue
  ((valid_lines += 1))
done < "$TMP/fixtures/test.jsonl"

if (( valid_lines != 2 )); then
  echo "FAIL: Expected 2 valid JSONL lines, got $valid_lines"
  exit 1
fi
echo "JSONL processing valid."

echo "All tests passed."
