#!/bin/bash
set -e

echo "Starting tests for gen_vhdl_ls.bash"

# Find the path to the real gen_vhdl_ls.bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GEN_SCRIPT="${SCRIPT_DIR}/gen_vhdl_ls.bash"

# Assertions
fail() {
  echo "FAIL: $1"
  return 1
}

assert_file_exists() {
  local file="$1"
  local msg="$2"
  if [[ ! -f "$file" ]]; then
    echo "FAIL: $msg"
    echo "File not found: $file"
    return 1
  fi
}

# Setup test environment
export TEST_DIR=$(mktemp -d)
export BUILD_WORKSPACE_DIRECTORY="${TEST_DIR}/workspace"
mkdir -p "${BUILD_WORKSPACE_DIRECTORY}"

export MOCK_BAZEL_BIN="${TEST_DIR}/bazel-bin"
mkdir -p "${MOCK_BAZEL_BIN}"

# Create a mock bazel command
MOCK_BAZEL_PATH="${TEST_DIR}/bin"
mkdir -p "${MOCK_BAZEL_PATH}"
cat << 'MOCK_EOF' > "${MOCK_BAZEL_PATH}/bazel"
#!/bin/bash
if [[ "$1" == "build" ]]; then
  echo "Mocking bazel build"
elif [[ "$1" == "info" && "$2" == "bazel-bin" ]]; then
  echo "${MOCK_BAZEL_BIN_VAL:-$MOCK_BAZEL_BIN}"
else
  echo "Unexpected bazel call: $@"
  exit 1
fi
MOCK_EOF
chmod +x "${MOCK_BAZEL_PATH}/bazel"

export PATH="${MOCK_BAZEL_PATH}:$PATH"

run_test() {
  local test_name="$1"
  echo "--- Running test: ${test_name} ---"

  # Clean up workspace and mock bazel-bin for each test
  rm -rf "${BUILD_WORKSPACE_DIRECTORY:?}/"*
  rm -rf "${MOCK_BAZEL_BIN:?}/"*
  unset MOCK_BAZEL_BIN_VAL
}

# Test 1: Basic generation (no add/prefix/suffix files)
run_test "basic_generation"
echo "lib1.files = ['a.vhd']" > "${MOCK_BAZEL_BIN}/part1.vhdl_ls_part"
echo "lib2.files = ['b.vhd']" > "${MOCK_BAZEL_BIN}/part2.vhdl_ls_part"

# Run the script
"${GEN_SCRIPT}"

assert_file_exists "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml" "vhdl_ls.toml should be generated"
# Read contents
OUTPUT=$(cat "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml")
# Check header
if [[ "$OUTPUT" != *"[libraries]"* ]]; then
  fail "Missing [libraries] header"
fi
# Check parts
if [[ "$OUTPUT" != *"lib1.files = ['a.vhd']"* ]]; then
  fail "Missing part1"
fi
if [[ "$OUTPUT" != *"lib2.files = ['b.vhd']"* ]]; then
  fail "Missing part2"
fi

# Test 2: Generation with vhdl_ls.toml.add
run_test "with_add_file"
echo "lib1.files = ['a.vhd']" > "${MOCK_BAZEL_BIN}/part1.vhdl_ls_part"
echo "# ADD CONTENT" > "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml.add"

"${GEN_SCRIPT}"

OUTPUT=$(cat "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml")
if [[ "$OUTPUT" != *"# ADD CONTENT"* ]]; then
  fail "Missing add content"
fi

# Test 3: Generation with vhdl_ls.toml.prefix
run_test "with_prefix_file"
echo "lib1.files = ['a.vhd']" > "${MOCK_BAZEL_BIN}/part1.vhdl_ls_part"
echo "# PREFIX CONTENT" > "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml.prefix"

"${GEN_SCRIPT}"

OUTPUT=$(cat "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml")
if [[ "$OUTPUT" != *"# PREFIX CONTENT"* ]]; then
  fail "Missing prefix content"
fi

# Test 4: Generation with vhdl_ls.toml.suffix
run_test "with_suffix_file"
echo "lib1.files = ['a.vhd']" > "${MOCK_BAZEL_BIN}/part1.vhdl_ls_part"
echo "# SUFFIX CONTENT" > "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml.suffix"

"${GEN_SCRIPT}"

OUTPUT=$(cat "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml")
if [[ "$OUTPUT" != *"# SUFFIX CONTENT"* ]]; then
  fail "Missing suffix content"
fi

# Test 5: Generation with both vhdl_ls.toml.add and vhdl_ls.toml.prefix
run_test "with_both_prefix_files"
echo "lib1.files = ['a.vhd']" > "${MOCK_BAZEL_BIN}/part1.vhdl_ls_part"
echo "# ADD CONTENT" > "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml.add"
echo "# PREFIX CONTENT" > "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml.prefix"

"${GEN_SCRIPT}"

OUTPUT=$(cat "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml")
if [[ "$OUTPUT" != *"# ADD CONTENT"* ]]; then
  fail "Missing add content when both files present"
fi
if [[ "$OUTPUT" != *"# PREFIX CONTENT"* ]]; then
  fail "Missing prefix content when both files present"
fi

# Test 6: Generation with relative bazel-bin
run_test "relative_bazel_bin"
export MOCK_BAZEL_BIN_VAL="bazel-bin"
mkdir -p "${BUILD_WORKSPACE_DIRECTORY}/bazel-bin"
echo "lib_rel.files = ['rel.vhd']" > "${BUILD_WORKSPACE_DIRECTORY}/bazel-bin/part_rel.vhdl_ls_part"

"${GEN_SCRIPT}"

OUTPUT=$(cat "${BUILD_WORKSPACE_DIRECTORY}/vhdl_ls.toml")
if ! echo "$OUTPUT" | grep -q "lib_rel.files = \['rel.vhd'\]"; then
  fail "Missing relative part content"
fi

echo "All tests passed."
rm -rf "$TEST_DIR"
