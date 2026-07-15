#!/usr/bin/env bash
#
# Unit tests for the local-script plugin.
# Validates that the script correctly preserves and executes
# bash variable expansion patterns (${VAR}, ${VAR:-default}).
#
# Usage: bash test/test-local-script.sh
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

assert_output() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        echo "  PASS: $test_name"
        ((PASS++))
    else
        echo "  FAIL: $test_name"
        echo "    expected to contain: $expected"
        echo "    got: $actual"
        ((FAIL++))
    fi
}

echo "=== local-script unit tests ==="
echo ""

# --- Test 1: ${VAR} brace expansion is preserved ---
echo "Test 1: \${VAR} brace expansion"
output=$(run_script 'MY_VAR=works; echo "result: ${MY_VAR}"')
assert_output "\${VAR} expands correctly" "result: works" "$output"

# --- Test 2: ${VAR:-default} parameter expansion is preserved ---
echo "Test 2: \${VAR:-default} parameter expansion"
output=$(run_script 'echo "result: ${UNDEFINED_XYZ:-fallback}"')
assert_output "\${VAR:-default} expands correctly" "result: fallback" "$output"

# --- Test 3: Environment variables with braces expand ---
echo "Test 3: Environment variable with braces"
export TEST_ENV_VAR="env_value"
output=$(run_script 'echo "result: ${TEST_ENV_VAR}"')
assert_output "\${ENV_VAR} expands from environment" "result: env_value" "$output"

# --- Test 4: plugin.yaml declares blankIfUnexpandable: false ---
echo "Test 4: plugin.yaml has blankIfUnexpandable: false"
count=$(grep -c "blankIfUnexpandable: false" "$PLUGIN_YAML")
if [[ "$count" -eq 2 ]]; then
    echo "  PASS: attribute set on both providers"
    ((PASS++))
else
    echo "  FAIL: expected 2 occurrences, found $count"
    ((FAIL++))
fi

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -gt 0 ]] && exit 1
exit 0
