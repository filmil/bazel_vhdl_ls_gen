_VHDL_LS_TAG = "vhdl_ls"
_VHDL_LS_LIB_PREFIX = "vhdl_ls_lib_"


def _vhdl_ls_aspect_impl(target, ctx):
    # We only care about the current target. No transitive aggregation needed
    # because the CLI will visit every target individually.

    vhdl_ls_files = []

    if ctx.rule.kind == "filegroup" and _VHDL_LS_TAG in ctx.rule.attr.tags:
        lib_name = "unnamed"
        for tag in ctx.rule.attr.tags:
            if tag.startswith("vhdl_ls_lib_"):
                lib_name = tag.removeprefix(_VHDL_LS_LIB_PREFIX)

        manifest_file = ctx.actions.declare_file(target.label.name + ".vhdl_ls_part")

        files_list = [f.path for f in target.files.to_list()]

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


