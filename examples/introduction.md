# Introduction

This collection of modules for the [SILE](https://github.com/sile-typesetter/sile) typesetting
system provides a complete redesign of its former native Markdown support, with
a great set of Pandoc-like extensions and plenty of extra goodies.

- `\autodoc:package{markdown}`{=sile} package: native support of Markdown.
- `\autodoc:package{djot}`{=sile} package: native support of Djot.
- `\autodoc:package{pandocast}`{=sile} package: native support of Pandoc JSON AST files.

For casual readers, this collection notably aims at easily converting Markdown or Djot documents to print-quality PDFs.
There is actually more than one solution to achieve great results in that direction:

 1. Directly using the native converter packages,
 1. Using the Pandoc software to generate an output suitable for SILE.

Each of them has its advantages, and a few limitations as well.

![Supported routes from input to output.](./markdown-sile-overview.dot){width="96%fw"}

## Installation

This module collection requires SILE v0.14 or upper.

Installation relies on the **luarocks** package manager.
To install the latest version, you may use the provided “rockspec”:

```bash
luarocks install markdown.sile
```

Refer to the SILE manual for more detailed 3rd-party package installation information.

## Usage

### Usage from command line

The following chapters describe the packages' features, and how to use them within existing documents (themselves in SIL, Djot or Markdown syntax).
It's perfectly possible, though, to perform direct conversion from the command line.
For instance, here is how it may be done for Markdown document...

```
sile -u inputters.markdown somefile.md
```

... Or for a Djot document.

```
sile -u inputters.djot somefile.dj
```

This method directly produces a PDF from the input file, using SILE's standard **book** class.[^intro-book-class]

[^intro-book-class]: Actually, it uses a **markdown** class derived from the standard book class and loading the required modules.
You don't really have to know that, unless you intend to invoke SILE with the `-c` option to specify another class of your choice; in that case you will need to load additional modules explicitly---unless it is a resilient class, of course.

### Usage with the resilient collection

To unleash the full potential of this package collection, we recommend that you also install our [**resilient.sile**](https://github.com/Omikhleia/resilient.sile) collection of classes and packages.

```bash
luarocks install resilient.sile
```

Then, you can automatically benefit from a few advanced features.
Conversion from command line just requires to load a resilient class, and optionally the poetry package.
For instance:

```
sile -c resilient.book -u inputters.markdown -u packages.resilient.poetry somefile.md
```

(And likewise for the Pandoc AST or Djot processing.)

A "resilient style file" is also generated.
It can be modified to change many styling decisions and adapt the output at convenience.

### Advanced usage from existing documents

While direct conversion from the command line may be adequate for very simple workflows, there are a number of things usually best addressed by using some kind of "wrapper" document.

This package collection provides several ways for including Markdown or Djot content in documents written in SIL syntax, the default mark-up language provided by SILE.
These are described further in this guide.

The resilient collection also introduces a "master document" format, streamlining several usual tasks. Give it a chance, and you may even end up producing a book with SILE without a single statement in SIL.

## Credits

Additional thanks to:

- Simon Cozens, _et al._ concerned, for the early attempts at using **lunamark** with SILE.
- Vít Novotný, for the good work on lunamark, and the impressive [**witiko/markdown**](https://github.com/Witiko/markdown) package for (La)TeX---a great source of inspiration and a goal of excellence.
- Caleb Maclennan, for his early work on a Pandoc-to-SILE converter which, though on different grounds, indirectly gave me the idea of the Pandoc AST alternative approach proposed here.
