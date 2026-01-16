#!/bin/bash
set -e
set -x

cd $BUILD_WORKSPACE_DIRECTORY

OUTPUT_FILE="vhdl_ls.toml"

bazel build //... \
  --aspects=@vhdl_ls_gen//vhdl_ls_aspect:vhdl_ls.bzl%vhdl_ls_aspect \
  --output_groups=vhdl_ls_manifests \
  --keep_going

# 3. Create the TOML header
echo "[libraries]" > "$OUTPUT_FILE"

# 4. Find all generated parts in bazel-bin and append them
# Note: We look inside bazel-bin based on the current package path
find "$(bazel info bazel-bin)" -name "*.vhdl_ls_part" -exec cat {} + >> "$OUTPUT_FILE"

# vim: filetype=bash :
