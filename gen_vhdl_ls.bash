#!/bin/bash
set -e

cd $BUILD_WORKSPACE_DIRECTORY

PREFIX_FILE="vhdl_ls.toml.add"

OUTPUT_FILE="vhdl_ls.toml"

bazel build //... \
  --aspects=@vhdl_ls_gen//vhdl_ls_aspect:vhdl_ls.bzl%vhdl_ls_aspect \
  --output_groups=vhdl_ls_manifests \
  --keep_going

if [[ -f "${PREFIX_FILE}" ]]; then
  cp "${PREFIX_FILE}" "${OUTPUT_FILE}"
fi

# 3. Create the TOML header
echo "[libraries]" >> "$OUTPUT_FILE"

# 4. Find all generated parts in bazel-bin and append them
# Note: We look inside bazel-bin based on the current package path
find "$(bazel info bazel-bin)" -name "*.vhdl_ls_part" -exec cat {} + >> "$OUTPUT_FILE"

# vim: filetype=bash :
