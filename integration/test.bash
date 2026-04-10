#! /usr/bin/env bash

set -e

# When running under bazel test, the test is executed in a sandbox.
# The files are available in the current directory or relative to it.

OUTPUT_FILE="vhdl_ls.toml"

if [[ ! -f "${OUTPUT_FILE}" ]]; then
  echo "Error: ${OUTPUT_FILE} not found."
  exit 1
fi

echo "Verifying ${OUTPUT_FILE} content..."

# Check for prefix (from vhdl_ls.toml.add)
grep -q "# Prefix." "${OUTPUT_FILE}" || (echo "Prefix not found"; exit 1)

# Check for library header
grep -q "\[libraries\]" "${OUTPUT_FILE}" || (echo "Library header not found"; exit 1)

# Check for specific libraries and files
grep -q "some_library.files = \[" "${OUTPUT_FILE}" || (echo "some_library not found"; exit 1)
grep -q "your_vhdl_lib/my_package.vhd" "${OUTPUT_FILE}" || (echo "File in some_library not found"; exit 1)

grep -q "some_other_library.files = \[" "${OUTPUT_FILE}" || (echo "some_other_library not found"; exit 1)
grep -q "my_vhdl_lib/my_package.vhd" "${OUTPUT_FILE}" || (echo "File in some_other_library not found"; exit 1)

# Check for suffix
grep -q "# Suffix" "${OUTPUT_FILE}" || (echo "Suffix not found"; exit 1)

echo "Integration test passed!"
exit 0
