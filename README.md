# markdown.sile

[![license](https://img.shields.io/github/license/Omikhleia/markdown.sile)](LICENSE)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/markdown.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/markdown.sile)

_EARLY PRE-RELEASE_

This collection of modules for the [SILE](https://github.com/sile-typesetter/sile) typesetting
system provides a complete redesign of the native Markdown support for SILE, with
a great set of Pandoc-like extensions and plenty of extra goodies.

- **markdown** inputter and package: native support of Markdown files.
- **pandocast** inputter and package: native support of Pandoc JSON AST files.

## Installation

This module collection requires SILE v0.14 or upper.

Installation relies on the **luarocks** package manager.

To install the latest development version, you may use the provided “rockspec”:

```
luarocks --lua-version 5.4 install --server=https://luarocks.org/dev markdown.sile
```

(Adapt to your version of Lua, if need be, and refer to the SILE manual for more
detailed 3rd-party package installation information.)

## Usage

From command line:

```
sile -u inputters.markdown somefile.md
```

From documents (e.g. here in SILE language)

```
\use[module=packages.markdown]
\include[src=somefile.md]
```

Other possibilities exists (such as setting `format=markdown` on the `\include` command, if the file extension
cannot be one of the supported variants, etc.). Refer to the SILE manual for more details on inputters and their
usage.

The "example" documentation/showcase in this repository additionaly requires the `autodoc` package, so you may
generate a PDF from it with:

```
sile -u inputters.markdown -u packages.autodoc examples/sile-and-markdown.md
```
