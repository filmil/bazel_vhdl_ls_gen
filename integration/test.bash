#! /usr/bin/env bash

set -e

TOML_FILE="vhdl_ls.toml"

if [[ ! -f "${TOML_FILE}" ]]; then
  echo "Error: ${TOML_FILE} not found."
  exit 1
fi

# Check for prefix
grep -q "# Prefix." "${TOML_FILE}"

# Check for libraries header
grep -q "\[libraries\]" "${TOML_FILE}"

# Check for some_library
grep -q "some_library.files = \[" "${TOML_FILE}"
grep -q "your_vhdl_lib/my_package.vhd" "${TOML_FILE}"

# Check for some_other_library
grep -q "some_other_library.files = \[" "${TOML_FILE}"
grep -q "my_vhdl_lib/my_package.vhd" "${TOML_FILE}"

# Check for some_other_library_2
grep -q "some_other_library_2.files = \[" "${TOML_FILE}"
grep -q "your_vhdl_lib_2/my_package.vhd" "${TOML_FILE}"

# Check for suffix
grep -q "# Suffix" "${TOML_FILE}"

# Assert that unsupported rule kinds with vhdl_ls tag do NOT produce output
if grep -q "unnamed.files" "${TOML_FILE}"; then
  echo "Error: Found 'unnamed' library in ${TOML_FILE}, which should not be there for unsupported rule kinds."
  exit 1
fi

if grep -q "unsupported.vhd" "${TOML_FILE}"; then
  echo "Error: Found 'unsupported.vhd' in ${TOML_FILE}, which should not be there."
  exit 1
fi

if grep -q "test.bash" "${TOML_FILE}"; then
  echo "Error: Found 'test.bash' in ${TOML_FILE}, which should not be there."
  exit 1
fi

echo "Integration test passed!"
exit 0
