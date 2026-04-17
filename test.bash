#! /usr/bin/env bash

set -euo pipefail

# Find the gen_vhdl_ls.bash script.
# When running under Bazel, it will be in the runfiles.
# When running manually, it might be in the current directory.
if [[ -f "./gen_vhdl_ls.bash" ]]; then
  GEN_VHDL_LS_SCRIPT="./gen_vhdl_ls.bash"
elif [[ -f "${BASH_SOURCE[0]%/*}/gen_vhdl_ls.bash" ]]; then
  GEN_VHDL_LS_SCRIPT="${BASH_SOURCE[0]%/*}/gen_vhdl_ls.bash"
else
  echo "Could not find gen_vhdl_ls.bash"
  exit 1
fi

source "${GEN_VHDL_LS_SCRIPT}"

# Mocking the functions/environment is not strictly necessary as we are testing
# assemble_vhdl_ls which takes paths as arguments.

test_assemble_vhdl_ls_basic() {
  echo "Running test_assemble_vhdl_ls_basic..."
  local test_dir=$(mktemp -d)
  # Ensure cleanup happens even if the test fails.
  trap "rm -rf ${test_dir}" RETURN

  local bazel_bin="${test_dir}/bazel-bin"
  mkdir -p "${bazel_bin}"
  local output_file="${test_dir}/vhdl_ls.toml"
  local prefix_file="${test_dir}/vhdl_ls.toml.add"
  local prefix_file2="${test_dir}/vhdl_ls.toml.prefix"
  local suffix_file="${test_dir}/vhdl_ls.toml.suffix"

  echo "PREFIX1" > "${prefix_file}"
  echo "SUFFIX" > "${suffix_file}"
  echo "PART1" > "${bazel_bin}/part1.vhdl_ls_part"
  echo "PART2" > "${bazel_bin}/part2.vhdl_ls_part"

  assemble_vhdl_ls "${bazel_bin}" "${output_file}" "${prefix_file}" "${prefix_file2}" "${suffix_file}"

  # Check content
  grep -q "PREFIX1" "${output_file}"
  grep -q "\[libraries\]" "${output_file}"
  grep -q "PART1" "${output_file}"
  grep -q "PART2" "${output_file}"
  grep -q "SUFFIX" "${output_file}"

  # Verify order of parts (part1 then part2 because of sort)
  local parts_pos1=$(grep -b "PART1" "${output_file}" | cut -d: -f1)
  local parts_pos2=$(grep -b "PART2" "${output_file}" | cut -d: -f1)
  if [[ ${parts_pos1} -ge ${parts_pos2} ]]; then
    echo "PART1 should come before PART2"
    return 1
  fi

  echo "test_assemble_vhdl_ls_basic passed."
}

test_assemble_vhdl_ls_prefix_override() {
  echo "Running test_assemble_vhdl_ls_prefix_override..."
  local test_dir=$(mktemp -d)
  trap "rm -rf ${test_dir}" RETURN

  local bazel_bin="${test_dir}/bazel-bin"
  mkdir -p "${bazel_bin}"
  local output_file="${test_dir}/vhdl_ls.toml"
  local prefix_file="${test_dir}/vhdl_ls.toml.add"
  local prefix_file2="${test_dir}/vhdl_ls.toml.prefix"
  local suffix_file="${test_dir}/vhdl_ls.toml.suffix"

  echo "PREFIX1" > "${prefix_file}"
  echo "PREFIX2" > "${prefix_file2}"

  assemble_vhdl_ls "${bazel_bin}" "${output_file}" "${prefix_file}" "${prefix_file2}" "${suffix_file}"

  # Check content: PREFIX2 should have overwritten PREFIX1 in the output
  if grep -q "PREFIX1" "${output_file}"; then
    echo "PREFIX1 should have been overwritten by PREFIX2"
    return 1
  fi
  grep -q "PREFIX2" "${output_file}"

  echo "test_assemble_vhdl_ls_prefix_override passed."
}

test_assemble_vhdl_ls_missing_files() {
  echo "Running test_assemble_vhdl_ls_missing_files..."
  local test_dir=$(mktemp -d)
  trap "rm -rf ${test_dir}" RETURN

  local bazel_bin="${test_dir}/bazel-bin"
  mkdir -p "${bazel_bin}"
  local output_file="${test_dir}/vhdl_ls.toml"
  local prefix_file="${test_dir}/non_existent_prefix"
  local prefix_file2="${test_dir}/non_existent_prefix2"
  local suffix_file="${test_dir}/non_existent_suffix"

  # No parts either
  assemble_vhdl_ls "${bazel_bin}" "${output_file}" "${prefix_file}" "${prefix_file2}" "${suffix_file}"

  # Should only contain empty line and [libraries]
  local line_count=$(wc -l < "${output_file}")
  # 1 for echo "" > output_file, 1 for [libraries]
  if [[ ${line_count} -ne 2 ]]; then
     echo "Expected 2 lines in output file, got ${line_count}"
     return 1
  fi
  grep -q "\[libraries\]" "${output_file}"

  echo "test_assemble_vhdl_ls_missing_files passed."
}

test_assemble_vhdl_ls_basic
test_assemble_vhdl_ls_prefix_override
test_assemble_vhdl_ls_missing_files

echo "All tests passed!"
exit 0
