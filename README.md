# markdown.sile

[![license](https://img.shields.io/github/license/Omikhleia/markdown.sile)](LICENSE)
[![Luacheck](https://img.shields.io/github/workflow/status/Omikhleia/markdown.sile/Luacheck?label=Luacheck&logo=Lua)](https://github.com/Omikhleia/markdown.sile/actions?workflow=Luacheck)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/markdown.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/markdown.sile)

This collection of modules for the [SILE](https://github.com/sile-typesetter/sile) typesetting
system provides a complete redesign of the native Markdown support for SILE, with
a great set of Pandoc-like extensions and plenty of extra goodies.

- **markdown** inputter and package: native support of Markdown files.
- **pandocast** inputter and package: native support of Pandoc JSON AST files.

For casual readers: This notably aims at converting a Markdown document to print-quality PDF.

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

Basic usage is described just below. A more complete PDF version of the documentation (but not
necessarily the latest, see also further below for generating it from the sources) should be
available [HERE](https://drive.google.com/file/d/19VfSMmfBIZwr43U-W842IkSE349wdgZb/view?usp=sharing).

### Native Markdown package

From command line:

```
sile -u inputters.markdown somefile.md
```

Or from documents (e.g. here in SILE language):

```
\use[module=packages.markdown]
\include[src=somefile.md]
```

Other possibilities exists (such as setting `format=markdown` on the `\include` command, if the file extension
cannot be one of the supported variants, etc.). Refer to the SILE manual for more details on inputters and their
usage.

Including raw Markdown content from within a SILE document is also possible:

```
\begin[type=markdown]{raw}
Some Markdown content
\end{raw}
```

### Pandoc AST alternative package

_Prerequisites:_ The [LuaJSON](https://github.com/harningt/luajson) module must be
installed and available to your SILE environment. This topic is not covered here.

First, using the appropriate version of Pandoc, convert your file to a JSON AST:

```
pandoc -t json somefile.md -f markdown -o somefile.pandoc
```

Then, from command line:

```
sile -u inputters.pandocast somefile.pandoc
```

Or from documents:

```
\use[module=packages.pandocast]
\include[src=somefile.pandoc]
```

## Generating the documentation

The example documentation/showcase in this repository additionaly requires the `autodoc` package, so you
may generate a PDF from it with as follows:

```
sile -u inputters.markdown -u packages.autodoc examples/sile-and-markdown.md
```

It assumes a default font, so a few things might not render as expected, and uses SILE's book class.

**Recommended:** For even best results (in this writer's biased opinion), provided you have installed the
[resilient](https://github.com/Omikhleia/resilient.sile) collection of classes and packages:

```
sile examples/sile-and-markdown-manual.sil
```

The latter SILE document also loads extra packages before switching to Markdown, and defines
additional commands and styles. Moreover, it includes an additional chapter, showcasing
other advanced topics and cool use cases. Needed fonts are Libertinus Serif, Symbola and Zallman Caps.

## Supported features

This is but an overview. For more details, please refer to the provided example Markdown document,
which also serves as documentation, showcase and reference guide.

- Standard Mardown typesetting (italic, bold, code, etc.)
- Smart typography (quotes, apostrophes, ellipsis, dashes, etc.)
- Headers and header attributes
- Horizontal rules
- Images (and image attributes, e.g. dimensions)
- Strikeout (a.k.a. deletions)
- Subscript and superscript
- Footnotes (both regular and inline syntax support)
- Fenced code blocks (with attributes)
- Bracketed spans and fenced divs (with provisions for language change, custom styles, etc.)
- Underlines
- Small caps
- Links
- Lists
  - Standard ordered lists and bullet lists
  - Fancy lists
  - Task lists (GFM-like syntax)
  - Definition lists
- Pipe tables (and table captions)
- Line blocks (with enhanced provision for poetry)
- Hard line breaks
- Raw attributes (escaping to inline SILE or Lua scripting)

## License

All SILE-related code and samples in this repository are released under the MIT License, (c) 2022 Omikhleia.

A vendored (subset) of the [lunamark](https://github.com/jgm/lunamark) Lua parsing library is
distributed alongside. All corresponding files (in the `lua-libraries` folder) are released under
the MIT license, (c) 2009 John MacFarlane, _et al._

## Credits

Additional thanks to:

- Simon Cozens, _et al._ concerned, for the early attempts at using lunamark with SILE.
- Vít Novotný, for the good work on lunamark, and the impressive [witiko/markdown](https://github.com/Witiko/markdown)
  package for (La)TeX - a great source of inspiration and a goal of excellence.
- Caleb Maclennan, for his early work on a Pandoc-to-SILE converter which, though on different grounds, indirectly
  gave me the idea of the "pandocast" alternative approach.
