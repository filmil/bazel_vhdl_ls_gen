#!/bin/bash
set -e

cd "$BUILD_WORKSPACE_DIRECTORY"

PREFIX_FILE="vhdl_ls.toml.add"
PREFIX_FILE2="vhdl_ls.toml.prefix"
SUFFIX_FILE="vhdl_ls.toml.suffix"

OUTPUT_FILE="vhdl_ls.toml"

# Determine bazel-bin path
if [[ -L "bazel-bin" ]]; then
  BAZEL_BIN="bazel-bin"
else
  BAZEL_BIN=$(bazel info bazel-bin 2>/dev/null || echo "bazel-bin")
fi

# Use ./ prefix for relative paths to prevent find from interpreting them as options
# Absolute paths are already safe as they start with /
if [[ "${BAZEL_BIN}" == /* ]]; then
  FIND_PATH="${BAZEL_BIN}"
else
  FIND_PATH="./${BAZEL_BIN}"
fi

# Clean up any stale manifest fragments from previous builds
# Use -L to ensure we traverse bazel-bin if it's a symlink
if [[ -d "${FIND_PATH}" ]]; then
  find -L "${FIND_PATH}" -name "*.vhdl_ls_part" -delete
fi

bazel build //... \
  --aspects=@vhdl_ls_gen//vhdl_ls_aspect:vhdl_ls.bzl%vhdl_ls_aspect \
  --output_groups=vhdl_ls_manifests \
  --keep_going

printf "" > "${OUTPUT_FILE}"

for f in "${PREFIX_FILE}" "${PREFIX_FILE2}"; do
  if [[ -f "$f" ]]; then
    cat "$f" >> "${OUTPUT_FILE}"
  fi
done

# 3. Create the TOML header
echo "[libraries]" >> "$OUTPUT_FILE"

# 4. Find all generated parts in bazel-bin and append them
# Note: We look inside bazel-bin based on the current package path
# Use -L to ensure we traverse bazel-bin if it's a symlink
find -L "${FIND_PATH}" -name "*.vhdl_ls_part" -print0 | sort -z | xargs -0 -r cat >> "$OUTPUT_FILE"

if [[ -f "${SUFFIX_FILE}" ]]; then
  cat "${SUFFIX_FILE}" >> "${OUTPUT_FILE}"
fi

# vim: filetype=bash :
