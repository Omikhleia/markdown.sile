# Introduction

This collection of modules for the [SILE](https://github.com/sile-typesetter/sile) typesetting
system provides a complete redesign of its former native Markdown support, with
a great set of Pandoc-like extensions and plenty of extra goodies.

- `\autodoc:package{markdown}`{=sile} inputter and package: native support of Markdown files.
- `\autodoc:package{pandocast}`{=sile} inputter and package: native support of Pandoc JSON AST files.
- `\autodoc:package{djot}`{=sile} inputter and package: native support of Djot files.

For casual readers, this collection notably aims at easily converting Markdown or Djot documents to print-quality PDFs.

## Installation and usage

### Installation

This module collection requires SILE v0.14 or upper.
Installation relies on the **luarocks** package manager.
To install the latest development version, you may use the provided “rockspec”:

```bash
luarocks --lua-version 5.4 install --dev markdown.sile
```

Adapt to your version of Lua, if need be, and refer to the SILE manual for more
detailed 3rd-party package installation information.

### Usage from command line

The following chapters describe the packages' features, and how to use them within existing documents (say, in SIL syntax).
It's perfectly possible, though, to perform direct conversion from the command line.
For instance, here is how it may be done for Markdown document...

```
sile -u inputters.markdown somefile.md
```

... Or for a Djot document.

```
sile -u inputters.djot -u packages.markdown somefile.dj
```

This method directly produces a PDF from the input file, using SILE's standard **book** class.

### Usage with the resilient collection

To unleash the full potential of this package collection, we recommend that
you also install our [**resilient.sile**](https://github.com/Omikhleia/resilient.sile)
collection of classes and packages.

Then, you can automatically benefit from a few advanced features.
Conversion from command line just requires to load a resilient class, and optionnaly
the poetry package. For instance:

```
sile -c resilient.book -u inputters.markdown -u packages.resilient.poetry somefile.md
```

(And likewise for the Pandoc AST or Djot processing.)

A "resilient style file" is also generated. It can be modified to change many styling
decisions and adapt the ouput at convenience.

### Credits

Additional thanks to:

- Simon Cozens, _et al._ concerned, for the early attempts at using **lunamark** with SILE.
- Vít Novotný, for the good work on lunamark, and the impressive [**witiko/markdown**](https://github.com/Witiko/markdown) package for (La)TeX---a great source of inspiration and a goal of excellence.
- Caleb Maclennan, for his early work on a Pandoc-to-SILE converter which, though on different grounds, indirectly gave me the idea of the Pandoc AST alternative approach proposed here.
