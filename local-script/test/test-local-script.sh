#!/usr/bin/env bash
#
# Tests for the local-script plugin.
# Verifies that ${VAR} brace expansion is preserved when
# blankIfUnexpandable: false is set in plugin.yaml.
#
# Usage: ./test-local-script.sh
#

SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../contents" && pwd)/local-script"
PLUGIN_YAML="$(cd "$(dirname "$0")/.." && pwd)/plugin.yaml"
PASS=0
FAIL=0

run_script() {
    local script_content="$1"
    local tmp_dir="/tmp/nixy-test-$$-$RANDOM"
    (
        export RD_JOB_LOGLEVEL="INFO"
        export RD_JOB_EXECID="test-$$"
        export RD_CONFIG_TMP="$tmp_dir"
        export RD_CONFIG_SCRIPT="$script_content"
        mkdir -p "$tmp_dir"
        bash "$SCRIPT_UNDER_TEST" --dummy 2>/dev/null
    )
    local rc=$?
    rm -rf "$tmp_dir"
    return $rc
}

assert_contains() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        echo "  PASS: $test_name"
        ((PASS++))
    else
        echo "  FAIL: $test_name"
        echo "    expected to contain: $expected"
        echo "    actual output:       $actual"
        ((FAIL++))
    fi
}

echo "=== local-script tests ==="
echo ""

# --- Test 1: Bare $VAR expansion ---
echo "Test 1: Bare \$VAR expansion"
output=$(run_script 'TEST_VALUE=hello_test; echo "bare: $TEST_VALUE"')
assert_contains "bare \$VAR expands correctly" "bare: hello_test" "$output"

# --- Test 2: ${VAR} brace expansion ---
echo "Test 2: \${VAR} brace expansion"
output=$(run_script 'TEST_VALUE=hello_braces; echo "braces: ${TEST_VALUE}"')
assert_contains "\${VAR} brace expansion works" "braces: hello_braces" "$output"

# --- Test 3: ${VAR:-default} parameter expansion ---
echo "Test 3: \${VAR:-default} parameter expansion"
output=$(run_script 'echo "default: ${UNDEFINED_VAR_XYZ:-fallback_value}"')
assert_contains "\${VAR:-default} expands correctly" "default: fallback_value" "$output"

# --- Test 4: Rundeck env vars expand via bash ---
echo "Test 4: Rundeck environment variables expand via bash"
export RD_JOB_USERNAME="testuser"
output=$(run_script 'echo "user: ${RD_JOB_USERNAME}"')
assert_contains "\${RD_JOB_USERNAME} expands via bash" "user: testuser" "$output"

# --- Test 5: plugin.yaml has blankIfUnexpandable: false on both providers ---
echo "Test 5: plugin.yaml configuration"
count=$(grep -c "blankIfUnexpandable: false" "$PLUGIN_YAML")
if [[ "$count" -eq 2 ]]; then
    echo "  PASS: blankIfUnexpandable: false set on both providers"
    ((PASS++))
else
    echo "  FAIL: expected 2 occurrences of blankIfUnexpandable: false, found $count"
    ((FAIL++))
fi

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
