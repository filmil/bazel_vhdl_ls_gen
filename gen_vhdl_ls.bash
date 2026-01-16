#!/bin/bash
set -e

cd $BUILD_WORKSPACE_DIRECTORY

PREFIX_FILE="vhdl_ls.toml.add"
PREFIX_FILE2="vhdl_ls.toml.prefix"
SUFFIX_FILE="vhdl_ls.toml.suffix"

OUTPUT_FILE="vhdl_ls.toml"

bazel build //... \
  --aspects=@vhdl_ls_gen//vhdl_ls_aspect:vhdl_ls.bzl%vhdl_ls_aspect \
  --output_groups=vhdl_ls_manifests \
  --keep_going

echo "" > "${OUTPUT_FILE}"

if [[ -f "${PREFIX_FILE}" ]]; then
  cp "${PREFIX_FILE}" "${OUTPUT_FILE}"
fi
if [[ -f "${PREFIX_FILE}" ]]; then
  cp "${PREFIX_FILE}" "${OUTPUT_FILE}"
fi
if [[ -f "${PREFIX_FILE2}" ]]; then
  cp "${PREFIX_FILE2}" "${OUTPUT_FILE}"
fi

# 3. Create the TOML header
echo "[libraries]" >> "$OUTPUT_FILE"

# 4. Find all generated parts in bazel-bin and append them
# Note: We look inside bazel-bin based on the current package path
find "$(bazel info bazel-bin)" -name "*.vhdl_ls_part" -exec cat {} + >> "$OUTPUT_FILE"

if [[ -f "#{SUFFIX_FILE}" ]]; then
  cat "${SUFFIX_FILE}" >> "${OUTPUT_FILE}"
fi

# vim: filetype=bash :
