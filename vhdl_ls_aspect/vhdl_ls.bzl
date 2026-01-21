_VHDL_LS_TAG = "vhdl_ls"
_VHDL_LS_LIB_PREFIX = "vhdl_ls_lib_"
_VHDL_LS_REM_PREFIX = "vhdl_ls_rem_"
_VHDL_LS_ADD_PREFIX = "vhdl_ls_add_"

_VHDL_RULE_KINDS = [
    "filegroup",
    "vhdl_library",
]


def _vhdl_ls_aspect_impl(target, ctx):
    # We only care about the current target. No transitive aggregation needed
    # because the CLI will visit every target individually.

    vhdl_ls_files = []

    path_remove = ""
    path_add = ""
    if ctx.rule.kind in _VHDL_RULE_KINDS and _VHDL_LS_TAG in ctx.rule.attr.tags:
        lib_name = "unnamed"
        for tag in ctx.rule.attr.tags:
            if tag.startswith(_VHDL_LS_LIB_PREFIX):
                lib_name = tag.removeprefix(_VHDL_LS_LIB_PREFIX)
            if tag.startswith(_VHDL_LS_REM_PREFIX):
                path_remove = tag.removeprefix(_VHDL_LS_REM_PREFIX)
            if tag.startswith(_VHDL_LS_ADD_PREFIX):
                path_add = tag.removeprefix(_VHDL_LS_ADD_PREFIX)

        manifest_file = ctx.actions.declare_file(target.label.name + ".vhdl_ls_part")

        files_list = [
            "{add}{path}".format(
                add=path_add,
                path=f.path.removeprefix(path_remove)) for f in target.files.to_list()]

        content = '{lib}.files = [\n{files}\n]\n'.format(
            lib = lib_name,
            files = ",\n".join(['  "{}"'.format(f) for f in files_list])
        )

        ctx.actions.write(
            output = manifest_file,
            content = content,
        )
        vhdl_ls_files.append(manifest_file)

    # Place the file in a named output group
    return [
        OutputGroupInfo(
            vhdl_ls_manifests = depset(vhdl_ls_files)
        )
    ]

vhdl_ls_aspect = aspect(
    implementation = _vhdl_ls_aspect_impl,
    # No attr_aspects needed, since we visit nodes via //...
)


