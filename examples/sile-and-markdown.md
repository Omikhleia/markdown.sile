# SILE and Markdown

::: {custom-style=raggedleft}
"Markdown is intended to be as easy-to-read and easy-to-write as is feasible."^[From the
original [Markdown syntax specification](https://daringfireball.net/projects/markdown/syntax).]
:::

While the original Markdown format was indeed quite simple, it quickly became a landmark for
documentation, especially technical. Several variants then emerged. Amongst other solutions, the Pandoc
converter started supporting a nice set of interesting extensions for lists, footnotes, tables,
etc.^[See [IETF RFC 7764, section 3.3](https://datatracker.ietf.org/doc/html/rfc7764#section-3.3).]
---So that nowadays, Markdown, enriched with these extensions, may be quite appealing to writers and
authors alike.

Within SILE’s aim to produce beautiful printed documents, it's a pretty reasonable assumption that
such writers and authors may want to use this fine typesetter with their Markdown content, without
having to learn the SIL language and its specifics (but not, either, fully excluding it for some
advanced capabilities). Guess what, the very chapter you are currently reading is written in Markdown!

[comment]: # (THIS TEXT SHOULD NOT APPEAR IN THE OUTPUT. It is actually the most platform independent comment in Markdown.)

## The native markdown package

Once you have loaded the `\autodoc:package{markdown}`{=sile} package,
the `\autodoc:command{\include[src=<file>]}`{=sile} command supports reading a Markdown file[^other-ways].
The speedy Markdown parsing relies on John MacFarlane's excellent **lunamark** Lua library.

[^other-ways]: The astute reader already knows, from reading the SILE manual, that there are other ways
(e.g. with command-line options) to tell SILE how to process a file in some format --- so we just stick
to the basics here.

```
\use[module=packages.markdown]
\include[src=somefile.md]
```

Embedding raw Markdown content from within a SIL document is also possible:

```
\begin[type=markdown]{raw}
Some **Markdown** content
\end{raw}
```

See also "[Configuration](#configuration)" further below.

### Basic typesetting {#basic-typesetting}

As it can be seen here, paragraphs and sectioning obviously works^[With a small caveat. The package maps heading
levels to `\chapter`, `\section`, `\subsection`, `\subsubsection` and uses a very basic fallback
if these are not found (or if the sectioning level gets past that point). The implication, therefore,
is that the class or other packages have to provide the relevant implementations.] are of course
supported. Pseudo-classes `.unnumbered` and `.notoc` are also supported.
As of formatting, *italic*, **bold**, and `code` all work as expected.

Hard line breaks...\
... are supported too, either using the standard "invisible" method from Markdown (i.e. two trailing
spaces at the end of a line) or a backslash-escaped newline (i.e. a backslash occurring at the
end of a line).

Several Pandoc-like extensions to Markdown are also supported.
Notably, the converter comes by default with smart typography enabled: three dashes (`---`) in an
inline text sequence are converted to an em-dash (---), two dashes (`--`)
to an en-dash useful for ranges (ex., "it's at pages 12--14"), and three dots
(`...`) to an ellipsis (...)

By the way, note, from the above example, that smart quotes and apostrophes are also automatically handled.

Likewise, superscripts and subscripts are available : H~2~O is a liquid, 2^10^ is 1024. This was
obtained with `H~2~O` and `2^10^` respectively.

Other nice features include:

 - ~~deletions~~ with `~~deletions~~`
 -  ==highlight== with `==highlight==`
 - [underlines]{.underline} with `[underlines]{.underline}`
 -  and even [Small Caps]{.smallcaps}, as `[Small Caps]{.smallcaps}`

The two latter cases use the extended Pandoc-inspired "span" syntax, which is also useful for languages
and custom styles (see further below). They also use the CSS-like class notation that several
Pandoc writers recognize.

### Horizontal dividers

In standard Markdown, a line containing a row of three or more asterisks, dashes, or underscores
(optionally separated by spaces) are supposed to produce a horizontal rule. This converter
however slightly deviates from that simple specification^[And also from Pandoc, therefore.
Quite obviously, the `\autodoc:package{pandocast}`{=sile} package will also only show
horizontal rules.],
for the mere reason that such a horizontal rule is seldom typographically sound
in many contexts.

Three asterisks produce a centered asterism.

***

Three space-separated asterisks produce a "dinkus".

* * *

Three dashes produce a centered horizontal rule, taking 20% of the line.

---

Four dashes produce a centered horizontal rule, taking 33% of the line.

----

Four space-separated dashes produce, provided appropriate package support is
available^[I.e. the **couyards.sile** package module is installed.], a nice curvy pendant.
What you see just below therefore depends on that support being present or not.

- - - -

Finally, without demonstrating it here, fourteen consecutive dashes enforce a page break.^[Why exactly
fourteen?
"The original says _fourteen_, but there is ample reason to infer that, as used by Asterion,
this numeral stands for _infinite_." (Jorge Luis [Borges]{.smallcaps}, "The House of Asterion".
In _Labyrinths: Selected Stories and Other Writings_, 1964.)]
It gives some flexibility to authors for marking a page break, and still get something visible
in its place with other converters.

Otherwise, everything else produces a full rule.^[Since this feature may elvove and support
more patterns, let's guarantee that underscores are reserved, and will always produce a full
horizontal rule. This author finds three or more underscores ugly and never used them in
Markdown; as of bad typography, it renders justice to the full rule.]

___

With all these variants at your disposal, you should be able to typeset print-quality
books and novels, with the appropriate dividers within chapters, or at the end of thereof.

### Lists

Unordered lists (a.k.a. itemized or bulleted lists) are obviously supported, or
we would not have been able to use them in the previous sections.

Ordered lists are supported as well, and also accept some of the "fancy lists" features
from Pandoc. The starting number is honored, and you have the flexibility to use
digits, roman numbers or letters (in upper or lower case).
The end delimiter, besides the standard period, can also be a closing parenthesis.

 b. This list uses lowercase letters and starts at 2. Er... at "b", that is.
     i) Roman number...
     i) ... followed by a right parenthesis rather than a period.

By the way,

 1. Nesting...

    ... works as intended.

     - Fruits
        - Apple
        - Orange
     - Vegetables
        - Carrot
        - Potato

    And that's all about regular lists.

Task lists following the GitHub-Flavored Markdown (GFM) format are supported too.

 - [ ] Unchecked item
 - [x] Checked item

Definition lists^[As in Pandoc, using the syntax of PHP Markdown Extra with some
extensions.] are also decently supported.

apples
  : Good for making applesauce.

citrus
  : Like oranges but yellow.

If your class or previously loaded packages provide a `defn` environment, it will be used.
Otherwise, the converter uses its own fallback method.

### Block quotes

> Block quotes are written like so.
>
> > They can be nested.

There's a small catch here. If your class or previously loaded packages provide
a `blockquote` environment, it will be used. Otherwise, the converter uses its
own fallback method.

### Footnotes


Here is a footnote call[^1].

[^1]: And here is some footnote text. But there were already a few foonotes earlier in this
document. Let's just add, as you can check in the source, that the converter supports several
syntaxes for footnotes.

### Languages

Language changes within the text are supported, either around "div" blocks or inline
"span" elements (both of those are Pandoc-like extensions to standard Markdown).
It is not much visible below, obviously, but the language setting
affects the hyphenation and other properties. In the case of French, for instance,
you can see the special thin space before the exclamation point, or the internal
spacing around quoted text:

::: {lang=fr}
> Cette citation est en français!
:::

Or inline in text: [«Encore du français!»]{lang=fr}

This was obtained with:

```
::: {lang=fr}
> Cette citation est en français!
:::

Or inline in text: [«Encore du français!»]{lang=fr}
```

Smart typography takes the current language into account when converting straight double and single
quotation marks to the appropriate typographic variant:
["English"]{lang=en} / ["Deutsch"]{lang=de} / ["français"]{lang=fr} / ["dansk"]{lang=da} / ["русский"]{lang=ru};
['English']{lang=en} / ['Deutsch']{lang=de} / ['français']{lang=fr} / ['dansk']{lang=da} / ['русский']{lang=ru}.^[For
most languages, `"` and `'` correspond to the primary and secondary quotations marks, respectively.
In some languages, they are used the other way round, but obviously the user's input is respected in those cases
(e.g. respectively ["Ghàidhlig"]{lang=cy} and ['Ghàidhlig']{lang=cy}).]

### Custom styles

On the "div" and "span" extended elements, the converter also supports the `{custom-style="..."}`
attribute.
This is, as a matter of fact, the same syntax as proposed by Pandoc, for instance, in
its **docx** writer, to specify a specific, possibly user-defined, custom style name (in that
case, a Word style, obviously). So yes, if you had a Pandoc-Markdown document styled for Word,
you might consider that switching to SILE is a viable option!

If such a named style exists, it is applied. Erm. What does it mean?
Well, in the default implementation, if used within in a **resilient** class and there is a corresponding style, the converter uses it.
Otherwise, if there is a corresponding SILE command by that name, the converter invokes it.
Otherwise, it just ignores the style and processes the content as-is.
Even if you do not use a resilient-compatible class, it thus allows you to use some interesting SILE features.
For instance, here is some block of text marked as "center":

::: {#centered custom-style="center"}
This is SILE at its best.
:::

And some inline [message]{custom-style="strong"}, marked as "strong". That's a fairly
contrived way to obtain a bold text, but you get the underlying general idea.

This logic is implemented in the `\autodoc:command{\markdown:custom-style:hook}`{=sile}
command.
Package or class designers may override this hook to support any
other additional styling mechanism they may have or want.
But basically, this is one of the ways to use SILE commands in Markdown.
While you could invoke _any_ SILE command with this feature, we recommend, though, to restrict it to styling.
You will see, further below, another more powerful way to leverage Markdown with SILE’s full processing capabilities.

### Images

Here is an image: ![Invisible caption as in inline](./gutenberg.jpg "An exemplary image"){width=1.5cm}

You can specify the required image width and/or height, as done just above actually,
by appending the `{width=... height=...}` attributes^[And possibly other attributes,
they are all passed through to the underlying SILE packages.] after the usual Markdown
image syntax ---Note that any unit system supported by SILE is accepted.

![This man is Gutenberg.](./gutenberg.jpg "An exemplary image"){#gutenberg width=3cm}

An image with nonempty caption (i.e. "alternate" text), occurring alone by itself in a paragraph,
will be rendered as a figure with a caption. If your class or previously loaded packages
provide a `captioned-figure` environment, it will be wrapped around the image (and it is then assumed to take care of a `\caption` content, i.e. to extract and display it
appropriately).^[When using the **resilient** classes, the caption will be numbered by
default, and added to the list of figures. Specify `.unnumbered`, and `.notoc` respectively,
if you do not want it.]
Otherwise, the converter uses its own fallback method.

Besides regular image files, a few specific file extensions are also recognized and
processed appropriately.
Notably ![](./examples/manicule.svg){height=0.6bs} SVG is supported too (`.svg`), as demonstrated
here with a "manicule" in that format.
Files in Graphviz DOT graph language (`.dot`) are supported and rendered as images too.

![The **markdown.sile** ecosystem (simplified).](./markdown-sile-schema.dot "A graph"){width="92%fw"}

### Maths

TeX-like math between `$` ("inline mode") or `$$` ("display mode") decently works.
Note that $20,000 and $30,000 don't parse as math, while $e^{i\pi}=-1$ does.
There is an important constraint, though: you have to restrict yourself to the syntax subset supported
by SILE. This being said, some nice fomulas may be achieved:

$$\pi=\sum_{k=0}^\infty\frac{1}{16^k}(\frac{4}{8k+1} − \frac{2}{8k+4} − \frac{1}{8k+5} − \frac{1}{8k+6})$$

### Tables {#tables}

The converter only supports the PHP-like "pipe table" syntax at this point, with an optional
caption.

| Right | Left | Default | Center |
|------:|:-----|---------|:------:|
|  12   |  12  |    12   |    12  |
|  123  |  123 |   123   |   123  |

  : Demonstration of a pipe table.

Regarding captioned tables, there's again a catch. If your class or previously loaded packages
provide a `captioned-table` environment, it will be wrapped around the table (and it is then assumed to
take care of a `\caption` content, i.e. to extract and display it appropriately).  Otherwise,
the converter uses its own fallback method.

### Line blocks

So called "line blocks", a sequence of lines beginning with a vertical bar (`|`) and followed by a
space, are also supported. The division into lines is preserved in the output. Any additional leading space
is preserved too, interpreted as an em-quad. These blocks can be useful for typesetting addresses
or poetry.

::: { custom-style=em }
| Long is one night, long is the
  next;
|  how can I bear three?
| A month has often seemed less to me
|  than this half night of longing.
:::

This implementation goes a bit beyond the standard Pandoc-inspired support for line blocks.
In particular, empty lines (i.e. starting with a vertical bar and a single space, but no other content
afterwards) are interpreted as stanza separators, which should be smaller than an empty line
(i.e. a small skip, by default).

::: { .poetry lang=fr step=4 }
| En hiver la terre pleure ;
| Le soleil froid, pâle et doux,
| Vient tard, et part de bonne heure,
| Ennuyé du rendez-vous.
| 
| Leurs idylles sont moroses.
| — [Soleil]{#sun} ! aimons ! — Essayons.
| Ô terre, où donc sont tes roses ?
| — Astre, où donc sont tes rayons ?
| 
| Il prend un prétexte, grêle,
| Vent, nuage noir ou blanc,
| Et dit : — C’est la nuit, ma belle ! —
| Et la fait en s’en allant ;
| 
| Comme un amant qui retire
| Chaque jour son cœur du nœud,
| Et, ne sachant plus que dire,
| S’en va le plus tôt qu’il peut.
:::

Moreover, there's once again a nice catch. If your class or previously loaded packages
provide a `poetry` environment, and you set the `.poetry` class specifier on a "div"
element just around the line blocks, then this environment will be used instead of
the default one provided by the converter. It is assumed to implement the same
features and options ---namely, `numbering` (boolean, true by default)^[For consistency
with headers, the `.unnumbered` class specifier is also supported.], `start` and `step`
(integers) and `first` (boolean, false by default)--- as the `\autodoc:package{resilient.poetry}`{=sile}
3rd-party package. For instance:

~~~
:::{ .poetry step=4 first=true }
| Some verses...
| Other verses...
:::
~~~

### Basic links

Here is a link to the [SILE website](https://sile-typesetter.org/).
It might not be visible in the PDF output, but hover it and click. It just works.
Likewise, here is an internal link to the "[Basic typesetting](#basic-typesetting)" section.

You can use attributes on links:
the [SILE website](https://sile-typesetter.org/){.underline}.^[Within a **resilient** class,
we'd possibly recommend using a custom style to color links, etc.]

### Cross-references

Neither standard Markdown nor Pandoc defines a proper way to insert cross-references of the kind
you would see in a book, as in the following example.

> The section on "[](#tables){ .title }", that is [](#tables){ .section },
> is on p. [](#tables){ .page }.

This converter takes a bold decision, though unlikely to break anything unexpected. Empty local links
(that is, without inline display content) are interpreted as cross-references. By default, they are
resolved to the closest numbering item, whatever that might be in the hierarchical structure of your
document. A pseudo-class attribute may be used to override the default behavior and specify which type
of reference is expected (page number, section number or title text). Thus, the above example was
obtained from the following input:

```
The section on "[](#tables){ .title }", that is [](#tables){ .section }, is on p.[](#tables){ .page }.
```

Besides heading levels, it also works for various elements where you can define an identifier,
for instance we had some centered text in section [](#centered). With appropriate class and package
support^[Typically, it works with the **resilient** collection of classes and packages. It won't
work with non-supporting class and packages, using the fallback implementation for captioned elements,
poetry, etc.],
you may even refer to Gutenberg as "figure [](#gutenberg)", or to some poetry verse
mentioning the Sun ("Soleil"), in [](#sun){.section}, as "verse [](#sun)".

### Code blocks

Verbatim code and "fenced code blocks" work:

```lua
function fib (n)
  -- Fibonacci numbers
  if n < 2 then return 1 end
  return fib(n - 2) + fib(n - 1)
end
```

As shown above, code blocks marked as being in Lua (either with the `lua` information string or the `.lua` class specifier) are syntax-highlighted. This is a naive approach, until the converter possibly supports a more general solution.

Code blocks marked as being in the Graphviz DOT language (either with the `dot` information string or the `.dot` class specifier) are rendered as images. When the attribute syntax is used, options are passed to the underlying processor. For instance, the image below is produced with
`{.dot width=5cm layout=neato}`.

``` {.dot width=5cm layout=neato}
graph {
  node [fillcolor="lightskyblue:darkcyan" style=filled gradientangle=270]
  a -- { b d };
  b -- { c e };
  c -- { f g h i };
  e -- { j k l m n o };
}
```

If you want the actual code to be displayed, rather than the converted image,
you can set the `render` attribute to false.

``` {.dot render=false width=5cm layout=neato}
graph {
  node [fillcolor="lightskyblue:darkcyan" style=filled gradientangle=270]
  a -- { b d };
  b -- { c e };
  c -- { f g h i };
  e -- { j k l m n o };
}
```

Code blocks marked as being in Markdown or Djot are interpreted too (again, unless
the `render` attribute is set to false).
This feature allows switching between those languages, would there be something one does not support yet.
For Markdown, attributes are passed to the converter, allowing to possibly use different compatibility options (see "[Configuration](#configuration)").

### Raw blocks

Last but not least, the converter supports a `{=sile}` annotation on code blocks, to pass
through their content in SIL language, as shown below.[^raw-comment]

[^raw-comment]: This is also a Pandoc-inspired extension to standard Markdown. Other `{=xxx}` annotations
than those described in this section are skipped (i.e. their whole content is ignored).
`That's a \LaTeX{} construct, so it's skipped in the SILE output.`{=latex}

```{=sile}
For instance, this \em{entire} sentence is typeset in a \em{raw block}, in SIL language.
```

Likewise, this is available on inline code elements: `\em{idem.}`{=sile}

This was obtained with:

~~~
```{=sile}
For instance, this \em{entire} sentence is typeset in a \em{raw block}, in SIL language.
```

Likewise, this is available on inline code elements: `\em{idem.}`{=sile}
~~~


It also supports `{=sile-lua}` to pass Lua code.
This is just a convenience compared to the preceding one, but it allows you to exactly
type the content as if it was in a code block (i.e. without having to bother wrapping
it in a script).

```{=sile-lua}
SILE.call("em", {}, { 'This' })
SILE.typesetter:typeset(" is called from Lua.")
```

This was generated by:

~~~
```{=sile-lua}
SILE.call("em", {}, { 'This' })
SILE.typesetter:typeset(" is called from Lua.")
```
~~~

You now have the best of two worlds in your hands, bridging together Markdown and SILE
so that you can achieve wonderful things, we have no idea of. Surprise us!

### HTML elements

For mere convenience, the `<br>` element is supported in addition to the standard ways to indicate
a hard line break (see the "[Basic typesetting](#basic-typesetting)" section),
therefore...<br>... it is honored.

Would you have a long word, such as
AAAAA<wbr>BBBBB<wbr>CCCCC<wbr>DDDDD<wbr>EEEEE<wbr>FFFFF<wbr>GGGGG<wbr>HHHHH<wbr>IIIII<wbr>JJJJJ<wbr>KKKKK<wbr>LLLLL<wbr>MMMM, the `<wbr>` element (introduced in HTML5) represents a word break opportunity.
It may help when the line-breaking rules would not otherwise create a break at acceptable locations.
In this admittedly lame example, we used it between groups of a same letter.

HTML entities are also processed, e.g. `&permil;` renders as &permil;.

### Smarter typography

On "span" elements, the `.decimal` pseudo-class attribute instructs the converter to consider numbers
in the content as decimal numbers, formatted with suitable decimal mark and digit grouping according
to the usage in the current language.
This allows, say, 1984 to be rendered as "[1984]{ .decimal } years ago" in English,
or "[1984 années]{ .decimal lang=fr }" in French, with appropriate separators.

Another pseudo-class `.nobreak` is supported on "span" elements. It ensures the content will not be line-broken. Use it wisely around small pieces of text or you might end up with more serious justification issues! Yet, it might be useful for proper names, etc.

When smart typography is enabled, the native converter also supports automatically converting
straight single and double quotes after digits to single and double primes.
It can be useful for easily typesetting units (e.g. 6")
or coordinates (e.g. Oxford is located at 51° 45' 7" N, 1° 15' 27" W).

## Configuration {#configuration}

Most Markdown syntax extensions are enabled by default.
You can pass additional options to
the `\autodoc:command{\include}`{=sile} command or the `\autodoc:environment[check=false]{raw}`{=sile} environment to tune the behavior of the Markdown parser.

::: {custom-style=raggedright}
> Available options are: `smart`, `smart_primes`, `strikeout`, `mark`, `subscript`, `superscript`,
> `definition_lists`, `notes`, `inline_notes`,
> `fenced_code_blocks`, `fenced_code_attributes`, `bracketed_spans`, `fenced_divs`,
> `raw_attribute`, `link_attributes`,
> `startnum`, `fancy_lists`, `task_list`, `hash_enumerators`, `table_captions`, `pipe_tables`, `header_attributes`,
> `line_blocks`, `escaped_line_breaks`, `tex_math_dollars`.
:::

For instance, to disable the smart typography feature:

```
\include[src=somefile.md, smart=false]
```

The `shift_headings` option can take an integer value and causes headers in included or embedded raw content to be offset (that is, shifted by the given amount).
For instance:

```
\include[src=somefile.md, shift_headings=1]
```

For document classes supporting it, this feature also allows you to access levels above the default scheme, such as "parts".

```
\include[src=somefile.md, shift_headings=-1]
```
