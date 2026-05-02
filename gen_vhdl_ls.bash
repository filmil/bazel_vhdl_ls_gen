#!/bin/bash
set -e

cd "$BUILD_WORKSPACE_DIRECTORY"

PREFIX_FILE="vhdl_ls.toml.add"
PREFIX_FILE2="vhdl_ls.toml.prefix"
SUFFIX_FILE="vhdl_ls.toml.suffix"

OUTPUT_FILE="vhdl_ls.toml"

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
BAZEL_BIN=$(bazel info bazel-bin 2>/dev/null || echo "bazel-bin")

# Use ./ prefix for relative paths to prevent find from interpreting them as options
# Absolute paths are already safe as they start with /
if [[ "${BAZEL_BIN}" == /* ]]; then
  FIND_PATH="${BAZEL_BIN}"
else
  FIND_PATH="./${BAZEL_BIN}"
fi

find "${FIND_PATH}" -name "*.vhdl_ls_part" -print0 | sort -z | xargs -0 -r cat >> "$OUTPUT_FILE"

if [[ -f "${SUFFIX_FILE}" ]]; then
  cat "${SUFFIX_FILE}" >> "${OUTPUT_FILE}"
fi

# vim: filetype=bash :
