# bazel_vhdl_ls_gen: autogenerate `vhdl_ls.toml`

[![Test](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/test.yml/badge.svg)](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/test.yml)
[![Tag and Release](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/tag-and-release.yml/badge.svg)](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/tag-and-release.yml)
[![Publish to my Bazel registry](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/publish.yml/badge.svg)](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/publish.yml)
[![Publish on Bazel Central Registry](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/publish-bcr.yml/badge.svg)](https://github.com/filmil/bazel_vhdl_ls_gen/actions/workflows/publish-bcr.yml)

The directory [integration](integration/) shows usage.

```python
module(
    name = "your_module",
    version = "0.0.1",
)

bazel_dep(name = "vhdl_ls_gen", version = "0.0.0") # Select version
```

Then tag each filegroup containing VHDL library files as follows:


```
load("@rules_shell//shell:sh_test.bzl", "sh_test")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "srcs",
    srcs = ["my_vhdl_lib/my_package.vhd"],
    tags = [
        # Add this tag to denote that these files should become part of a library.
        "vhdl_ls",
        # Add this tag to name the library `some_library`. That is what vhdl_ls
        # will know it as.
        "vhdl_ls_lib_some_library",
    ],
)

filegroup(
    name = "srcs_2",
    srcs = ["my_vhdl_lib/my_package.vhd"],
    # This repeats the above exercise, but with a different library.
    tags = ["vhdl_ls", "vhdl_ls_lib_some_other_library"],
)
```

Now you can do the following to regenerate `vhdl_ls.toml`:

```
bazel run @vhdl_ls_gen//:gen
```

This will collect all marked targets in the project and add write them to
the file named `vhdl_ls.toml` in your project's root directory.

This is simplistic, but will be enough as a proof of concept, before any
further features are added.

Unfortunately, we can not use `@basel_lib//lib:write_source_files.bzl`, because
this technique relies on using bazel aspects, and can not be invoked during the
regular build process. This is because we wanted to avoid having to collect
all libraries in a `deps`, but rather allow producing the generated `vhdl_ls.toml`
from tagged filegroups.

The reason this operates on filegroups is because different VHDL tooling requires
reusing source file lists anyways, so you are bound to have tool-independent
file definitions already.

If you need to add custom content to the generated file, create a file named
`vhdl_ls.toml.add`, and add any content to be put into the *header* of the file.

