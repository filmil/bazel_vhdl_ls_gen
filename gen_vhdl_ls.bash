#!/bin/bash
set -e

# Assemble the vhdl_ls.toml file from various parts.
# Arguments:
#   $1: The path to the bazel-bin directory.
#   $2: The path to the output file (vhdl_ls.toml).
#   $3: The path to the prefix file (vhdl_ls.toml.add).
#   $4: The path to the second prefix file (vhdl_ls.toml.prefix).
#   $5: The path to the suffix file (vhdl_ls.toml.suffix).
assemble_vhdl_ls() {
  local bazel_bin="$1"
  local output_file="$2"
  local prefix_file="$3"
  local prefix_file2="$4"
  local suffix_file="$5"

  echo "" > "${output_file}"

  if [[ -f "${prefix_file}" ]]; then
    cp "${prefix_file}" "${output_file}"
  fi
  if [[ -f "${prefix_file2}" ]]; then
    # Note: This overwrites the previous prefix if both exist,
    # which is the original behavior.
    cp "${prefix_file2}" "${output_file}"
  fi

  # 3. Create the TOML header
  echo "[libraries]" >> "${output_file}"

  # 4. Find all generated parts in bazel-bin and append them
  # We sort them to ensure deterministic output.
  find "${bazel_bin}" -name "*.vhdl_ls_part" | sort | xargs -r cat >> "${output_file}"

  if [[ -f "${suffix_file}" ]]; then
    cat "${suffix_file}" >> "${output_file}"
  fi
}

main() {
  cd "$BUILD_WORKSPACE_DIRECTORY"

  local prefix_file="vhdl_ls.toml.add"
  local prefix_file2="vhdl_ls.toml.prefix"
  local suffix_file="vhdl_ls.toml.suffix"
  local output_file="vhdl_ls.toml"

  bazel build //... \
    --aspects=@vhdl_ls_gen//vhdl_ls_aspect:vhdl_ls.bzl%vhdl_ls_aspect \
    --output_groups=vhdl_ls_manifests \
    --keep_going

  assemble_vhdl_ls "$(bazel info bazel-bin)" "${output_file}" "${prefix_file}" "${prefix_file2}" "${suffix_file}"
}

# If we are not being sourced, run the main function.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# vim: filetype=bash :
