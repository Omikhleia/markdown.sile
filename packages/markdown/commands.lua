--- Common commands for Markdown support in SILE, when there is no
-- direct mapping to existing commands or packages.
--
-- Split in a standalone package so that it can be reused and
-- generalized somewhat independently from the undelying parsing code.
--
-- @copyright License: MIT (c) 2022-2024 Omikhleia, Didier Willis
-- @module packages.markdown.commands
--
require("silex.lang") -- Compatibility layer
require("silex.ast")  -- Compatibility layer

local utils = require("packages.markdown.utils")
local hasClass = utils.hasClass

local createCommand, createStructuredCommand,
      removeFromTree, subContent
        = SU.ast.createCommand, SU.ast.createStructuredCommand,
          SU.ast.removeFromTree, SU.ast.subContent

local base = require("packages.base")

local package = pl.class(base)
package._name = "markdown.commands"

-- A small utility class that allows wrapping commands applied to a
-- content, avoiding a callback hell with conditionals where it is
-- used and providing a sequence-oriented presentation.
local CommandCascade = pl.class({
  _init = function (self)
    self.inner = {}
    self.outer = nil
  end,
  call = function (self, command, options)
    local out = self.outer and { self.outer } or self.inner
    self.outer = createStructuredCommand(command, options, out)
  end,
  tree = function (self, content)
    -- Return the cascaded AST without processing it
    for _, v in ipairs(content) do
      self.inner[#self.inner + 1] = v
    end
    local stacked = self.outer and { self.outer } or self.inner
    return stacked
  end,
  process = function (self, content)
    -- For convenience
    SILE.process(self:tree(content))
  end,
})

local UsualSectioning = { "part", "chapter", "section", "subsection", "subsubsection" }
local function getSectioningCommand (level)
  local index = level + 1
  if index > 0 and index <= #UsualSectioning then
    -- Check we actually have those commands (e.g. some classes might not
    -- have subsubsections.)
    if SILE.Commands[UsualSectioning[index]] then
      return UsualSectioning[index]
    end
    SU.warn("Unknown command \\"..UsualSectioning[index].." (fallback to a default generic header)")
    -- Default to something anyway.
    return "markdown:fallback:header"
  end
  -- Also default to something anyway, but different message
  SU.warn("No support found for heading level "..level.." (fallback to a default generic header)")
  return "markdown:fallback:header"
end

local function hasLinkContent(tree)
  if type(tree) == "table" then
    return #tree > 1 or hasLinkContent(tree[1])
  end
  if type(tree) == "string" and tree ~= "" then
    return true
  end
  return false
end

-- AST helper for the "implicit figure"
-- (tricky) This assumes a lot of knowledge about the AST...
local function implicitFigure (paracontent)
  local image, caption

  -- Does the paragraph content contain a single image element
  local command = type(paracontent) == "table" and #paracontent == 1 and paracontent[1].command
  if command == "markdown:internal:image" then
    image = paracontent[1]
    -- Does it have a non-empty caption...
    if (type(image[1]) == "string")
       or (type(image[1]) == "table" and #image[1] >= 1) then
      caption = image[1]
    end
  end
  return image, caption
end

-- Default color theme for syntax highlighted Lua code blocks
-- Very loosely based on the 'earendel' vim style.
local naiveLuaCodeTheme = {
  comment = { color = "#558817", italic = true },
  keyword = { color = "#2239a8", bold = true },
  iden = { color = "#0e7c6b" },
  number = { color = "#a8660d" },
  string = { color = "#a8660d" },
}

-- Inputfilter callback for splitting strings at numbers and formatting
-- them as decimal numbers.
local function decimalFilter (input, _)
  local t = {}
  for token in SU.gtoke(input, "%d+%.?%d*") do
    if(token.string) then
      t[#t+1] = token.string
    else
      t[#t+1] = createCommand("markdown:internal:decimal", {}, token.separator)
    end
  end
  return t
end

local function wrapLinkContent (options, content)
  local passedOptions = pl.tablex.copy(options) -- shallow
  -- We already took care of these.
  passedOptions.src = nil
  passedOptions.id = nil
  -- We don't need an extra span if there are no other options.
  -- N.B. we don't remove cross-reference elements from the class option
  -- so we'll end up always wrapping a span in those cases.
  -- I deem it's acceptable.
  if next(passedOptions) ~= nil then
    -- Wrap a span into the AST directly, it plays better with styles when we
    -- do not invoke functions.
    content = { createCommand("markdown:internal:span", passedOptions, subContent(content)) }
  end
  return content
end

function package:loadPackageAlt(resilientpack, legacypack)
  if not self.class.packages[resilientpack] then
    -- In resilient context, try enforcing the use of resilient variants,
    -- assuming its compatible with SILE's legacy implementation (command-wise),
    -- so that we benefit from its extended features and its styling.
    if self.isResilient then
      self:loadPackage(resilientpack)
    else
      self:loadPackage(legacypack)
    end
  end
end

-- For feature detection.
-- NOTE: The previous implementation was clever;
--   local ok, ResilientBase = pcall(require, 'classes.resilient.base')
--   return ok and self.class:is_a(ResilientBase)
-- However this loads the class, which loads all the silex extensions, even if
-- the class is not used...
-- Enforcing the silex extensions is not what we wanted.
-- So we are back to a more naive implementation, checking the class hierarchy
-- by name.
-- This is lame and knows too much about internals, but heh.
local function isResilientClass(cl)
  while cl do
    if cl._name == "resilient.base" then
      return true
    end
    cl = cl._base
  end
  return false
end

function package:_init (_)
  base._init(self)

  -- Check if document class is a resilient class or derived from one
  self.isResilient = isResilientClass(self.class)
  SU.debug("markdown", self.isResilient and "Used in a resilient class" or "Used in a non-resilient class")

  -- Only load low-level packages (= utilities)
  -- The class should be responsible for loading the appropriate higher-level
  -- constructs, see fallback commands further below for more details.
  self:loadPackage("color")
  self:loadPackage("embedders")
  self:loadPackage("image")
  self:loadPackage("inputfilter")
  self:loadPackage("labelrefs")
  self:loadPackage("math")
  self:loadPackage("ptable")
  self:loadPackage("rules")
  self:loadPackage("smartquotes")
  self:loadPackage("svg")
  self:loadPackage("textsubsuper")
  self:loadPackage("url")

  -- Do those at the end so the resilient versions may possibly override things.
  self:loadPackageAlt("resilient.lists", "lists")
  self:loadPackageAlt("resilient.verbatim", "verbatim")

  -- Optional packages
  pcall(function () return self:loadPackage("couyards") end)

  -- Other conditional packages
  if self.isResilient then
    self:loadPackage("resilient.epigraph")
  end
end

function package:hasCouyards ()
  return self.class.packages["couyards"]
end

function package.declareSettings (_)
  SILE.settings:declare({
    parameter = "markdown.fixednbsp",
    type = "boolean",
    default = false,
    help = "Fixed-width non-breakable space."
  })
end

function package:registerCommands ()
  -- A. Commands (normally) intended to be used by this package only.

  self:registerCommand("markdown:internal:paragraph", function (_, content)
    -- Implicit figure: "An image with nonempty alt text, occurring by itself in a paragraph,
    -- will be rendered as a figure with a caption. The image’s alt text will be used as the
    -- caption."
    local image, caption = implicitFigure(content)
    if image and caption then
      -- (tricky) This assumes a lot of knowledge about the AST...
      -- We cannot make a functional call here, because captioned elements later
      -- work by "extracting" the caption from the AST... So we rebuild the
      -- expected AST.
      if image.options.id then
        -- We'll want the ID to apply to the captioning environment (to potentially
        -- use the caption numbering)
        local id = image.options.id
        image.options.id = nil
        -- We also propagate image options to the englobing environment
        SILE.call("markdown:internal:captioned-figure", image.options, {
          image,
          createCommand("caption", {}, {
            createCommand("label", { marker = id }),
            caption,
          }),
        })
      else
        -- We also propagate image options to the englobing environment
        SILE.call("markdown:internal:captioned-figure", image.options, {
          image,
          createCommand("caption", {}, caption),
        })
      end
    else
      SILE.process(content)
      -- See comment on the lunamark writer layout option. With the default layout,
      -- this \par was not necessary... We switched to "compact" layout, to decide
      -- how to handle our own paragraphing.
      SILE.call("par")
    end
  end, "Paragraphing in Markdown (internal)")

  self:registerCommand("markdown:internal:thematicbreak", function (options, _)
    if hasClass(options, "asterism") then
      -- Asterism
      SILE.call("center", {}, { "⁂" })
    elseif hasClass(options, "dinkus") then
      -- Dinkus (with em-spaces)
      SILE.call("center", {}, { "* * *" })
    elseif hasClass(options, "bigrule") then
      -- 33% line
      SILE.call("center", {}, function ()
        SILE.call("raise", { height = "0.5ex" }, function ()
          SILE.call("hrule", { width = "33%lw", height = "0.4pt" })
        end)
      end)
    elseif hasClass(options, "fullrule") and self:hasCouyards() then
      -- Full line
      SILE.call("fullrule", { thickness = "0.4pt" })
    elseif hasClass(options, "pendant") and self:hasCouyards() then
      -- Pendant, with more options available than in Markdown
      local opts = {
        type = SU.cast("integer", options.type or 6),
        height = options.height,
        width = not options.height and (options.width or "default")
      }
      SILE.call("smallskip")
      SILE.call("couyard", opts)
    elseif not hasClass(options, "none") then
      -- 20% line
      SILE.call("center", {}, function ()
        SILE.call("raise", { height = "0.5ex" }, function ()
          SILE.call("hrule", { width = "20%lw", height = "0.4pt" })
        end)
      end)
    end

    if hasClass(options, "pagebreak") then
      SILE.call("eject")
    end
  end, "Thematic break in Djot (internal)")

  self:registerCommand("markdown:internal:hrule", function (options, _)
    if options.separator == "***" then
      -- Asterism
      SILE.call("center", {}, { "⁂" })
    elseif options.separator == "* * *" then
      -- Dinkus (with em-spaces)
      SILE.call("center", {}, { "* * *" })
    elseif options.separator == "---" then
        -- 20% line
        SILE.call("center", {}, function ()
          SILE.call("raise", { height = "0.5ex" }, function ()
            SILE.call("hrule", { width = "20%lw", height = "0.4pt" })
        end)
      end)
    elseif options.separator == "----" then
      -- 33% line
      SILE.call("center", {}, function ()
        SILE.call("raise", { height = "0.5ex" }, function ()
          SILE.call("hrule", { width = "33%lw", height = "0.4pt" })
        end)
      end)
    elseif options.separator == "- - - -" and self:hasCouyards() then
      -- Pendant (fixed choice = the one I regularly use)
      SILE.call("smallskip")
      SILE.call("couyard", { type = 6, width = "default" })
    elseif options.separator == "--------------" then -- Page break
      SILE.call("eject")
    else
      -- Full line
      SILE.call("fullrule", { thickness = "0.4pt" })
    end
  end, "Horizontal rule in Markdown (internal)")

  self:registerCommand("markdown:internal:header", function (options, content)
    local level = SU.required(options, "level", "header")
    local command = getSectioningCommand(SU.cast("integer", level))
    -- Pass all attributes to underlying sectioning command, and interpret
    -- .unnumbered and .notoc pseudo-classes as alternatives to numbering=false
    -- and toc=false.
    local id = options.id
    options.id = nil -- cancel attribute here.
    if hasClass(options, "unnumbered") then
      options.numbering = false
    end
    if hasClass(options, "notoc") then
      options.toc = false
    end
    if self.isResilient then
      --Sectioning commands support the marker option.
      options.marker = id
      SILE.call(command, options, content)
    else
      -- We don't know if the marker option is supported.
      -- Presumably no, e.g. it's the SILE default book class...
      -- Things are somewhat messy then, as of how to insert the identifier label.
      -- If done before the sectioning, it could end on the previous page.
      -- Within the title content, it poses other problems to ToC entries, running headers...
      -- We are left with doing it after, but that's not perfect either vs.
      -- page breaks, paragraph indents and skips...
      SILE.call(command, options, content)
      if id then
        if not self.warnResilient then
          SU.warn([[You are not using a resilient class.
Sectioning command (]] .. command .. [[) with an identifier (]] .. id .. [[)
may sometimes introduce weird skips.
Please consider using a resilient-compatible class!]])
          self.warnResilient = true
        end
        SILE.call("label", { marker = id })
      end
    end
  end, "Header in Markdown (internal)")

  self:registerCommand("markdown:internal:div:id", function (options, content)
    local id = SU.required(options, "id", "div")
    SILE.call("label", { marker = id })
    SILE.process(content)
  end, "Add a cross reference marker before the div content (internal)")

  self:registerCommand("markdown:internal:div", function (options, content)
    local cascade = CommandCascade()
    if options.id then
      -- A bit tricky here in command cascading, so let's delegate.
      cascade:call("markdown:internal:div:id", { id = options.id})
    end
    if options.lang then
      cascade:call("language", { main = options.lang })
    end
    if options["custom-style"] then
      -- The style (or the hook) is reponsible for paragraphing
      cascade:call("markdown:custom-style:hook", { name = options["custom-style"], scope = "block" })
    else
      cascade:call("markdown:internal:paragraph")
    end
    if hasClass(options, "poetry") then
      -- If the class or loaded packages provide a poetry environment and the div contains
      -- a lineblock structure only, then use the poetry environment instead.
      -- (tricky) This assumes a lot of knowledge about the AST...
      if SILE.Commands["poetry"] and #content == 1 and content[1].command == "markdown:internal:lineblock" then
        content[1].command = "poetry"
        content[1].options = content[1].options or {}
        content[1].options.first = SU.boolean(options.first, false)
        if hasClass(options, "unnumbered") then
          content[1].options.numbering = false
        else
          content[1].options.numbering = SU.boolean(options.numbering, true)
        end
        content[1].options.step = options.step and SU.cast("integer", options.step)
        content[1].options.start = options.start and SU.cast("integer", options.start)
      end
    end
    cascade:process(content)
  end, "Div in Markdown (internal)")

  self:registerCommand("markdown:internal:decimal", function (_, content)
    SILE.typesetter:typeset(SU.formatNumber(content[1], { style = "decimal" }))
  end, "Formats a (number) content string as decimal (internal)")

  self:registerCommand("markdown:internal:span", function (options, content)
    if hasClass(options, "decimal") then
      content = self.class.packages.inputfilter:transformContent(content, decimalFilter)
    end

    if options.id then
      SILE.call("label", { marker = options.id })
    end

    local cascade = CommandCascade()
    if options.lang then
      cascade:call("language", { main = options.lang })
    end
    if hasClass(options, "smallcaps") then
      cascade:call("font", { features = "+smcp" })
    end
    if hasClass(options, "mark") then
      cascade:call("color", { color = "red" }) -- FIXME TODO We'd need real support
    end
    if hasClass(options, "strike") then
      cascade:call("strikethrough")
    end
    if hasClass(options, "underline") then
      cascade:call("underline")
    end
    if options["custom-style"] then
      cascade:call("markdown:custom-style:hook", { name = options["custom-style"], scope = "inline" })
    end
    if hasClass(options, "nobreak") then
      cascade:call("hbox")
    end
    cascade:process(content)
  end, "Span in Markdown (internal)")

  self:registerCommand("markdown:internal:image", function (options, _)
    local uri = SU.required(options, "src", "image")
    if options.id then
      SILE.call("label", { marker = options.id })
    end
    local ext = utils.getFileExtension(uri)
    if ext == "svg" then
      SILE.call("svg", options)
    elseif ext == "dot" then
      options.format = "dot"
      SILE.call("embed", options)
    else
      SILE.call("img", options)
    end
  end, "Image in Markdown (internal)")

  self:registerCommand("markdown:internal:link", function (options, content)
    local uri = SU.required(options, "src", "link")
    if options.id then
      SILE.call("label", { marker = options.id })
    end
    if uri:sub(1,1) == "#" then
      -- local hask link
      local dest = uri:sub(2)
      if hasLinkContent(content) then
        content = wrapLinkContent(options, content)
        -- HACK. We use the target of a `\label`, knowing it is
        -- internally prefixed by "ref:" in the labelrefs package.
        -- That's not very nice to rely on internals...
        SILE.call("pdf:link", { dest = "ref:" .. dest }, content)
      else
        -- link with no textual content: we use them as a cross-references.
        local reftype
        if hasClass(options, "page") then reftype = "page"
        elseif hasClass(options, "section") then reftype = "section"
        elseif hasClass(options, "title") then reftype = "title"
        else reftype = "default" end
        SILE.call("ref", { marker = dest, type = reftype })
      end
    else
      if hasLinkContent(content) then
        content = wrapLinkContent(options, content)
        SILE.call("href", { src = uri }, content)
      else
        SU.warn("Ignored empty link to target "..uri)
      end
    end
  end, "Link in Markdown (internal)")

  self:registerCommand("markdown:internal:footnote", function (options, content)
    if not SILE.Commands["footnote"] then
      -- The reasons for NOT loading a package for this high-level structure
      -- is that the class or other packages may provide their own implementation
      -- (e.g. formatted differently, changed to endnotes, etc.).
      -- So we only do it as a fallback if mising, to degrade gracefully.
      SU.warn("Trying to enforce fallback for unavailable \\footnote command")
      self.class:loadPackage("footnotes")
    end
    if options.id then
      content = {
        createCommand("label", { marker = options.id }),
        subContent(content)
      }
    end
    SILE.call("footnote", options, content)
  end, "Footnote in Markdown (internal)")

  self:registerCommand("markdown:internal:rawinline", function (options, content)
    local format = SU.required(options, "format", "rawcontent")
    local rawtext = content[1]
    if type(rawtext) ~= "string" then
      SU.error("Raw inline content shall be a string, something bad occurred in markdown processing")
    end
    if format == "sile" then
      -- https://github.com/Omikhleia/markdown.sile/issues/39
      -- SILE 0.14.0..0.14.5 did not require the raw text to be wrapped in a
      -- document tree. But SILE 0.14.6 now does, or it errors.
      -- I checked that a least SILE 0.14.4 is ok too with that document
      -- wrapping, so the workaround just below seems safe and compatible...
      rawtext = "\\document{"..rawtext.."}"
      SILE.processString(rawtext, "sil")
    elseif format == "sile-lua" then
      SILE.processString(rawtext, "lua")
    elseif format == "html" then
      if rawtext:match("^<br[>/%s]") then
        SILE.call("markdown:internal:hardbreak")
      elseif rawtext:match("^<wbr[>/%s]") then
        SILE.call("penalty", { penalty = 100 })
      end
    end
  end, "Raw native inline content in Markdown (internal)")

  self:registerCommand("markdown:internal:hardbreak", function (_, _)
    -- We don't want to use a cr here, because it would affect parindents,
    -- insert a parskip, and maybe other things.
    -- It's a bit tricky to handle a hardbreak depending on depending on the
    -- alignment of the paragraph:
    --    justified = we can't use a break, a cr (hfill+break) would work
    --    ragged left = we can't use a cr
    --    centered = we can't use a cr
    --    ragged right = we don't care, a break is sufficient
    -- Knowning the alignment is not obvious, neither guessing it from the skips.
    -- Using a parfillskip seems to do the trick, but it's maybe a bit hacky.
    -- This is nevertheless what would have occurred with a par in the same
    -- situation.
    SILE.typesetter:pushGlue(SILE.settings:get("typesetter.parfillskip"))
    SILE.call("break")
  end, "Hard break in Markdown (internal)")

  self:registerCommand("markdown:internal:rawblock", function (options, content)
    local format = SU.required(options, "format", "rawcontent")
    if format == "sile" or format == "sile-lua" then
      SILE.call("markdown:internal:paragraph", {}, function ()
        SILE.call("markdown:internal:rawinline", options, content)
      end)
    end
  end, "Raw native block in Markdown (internal)")

  self:registerCommand("markdown:internal:blockquote", function (_, content)
    -- Would be nice NOT having to do this, but SILE's plain class only has a "quote"
    -- environment that doesn't really nest, and hard-codes all its values, skips, etc.
    -- So we might have a better version provided by a user-class or package.
    -- Otherwise, use our own fallback (with hard-coded choices too, but a least
    -- it does some proper nesting)
    if not SILE.Commands["blockquote"] then
      SILE.call("markdown:fallback:blockquote", {}, content)
    else
      SILE.call("blockquote", {}, content)
    end
  end, "Block quote in Markdown (internal)")

  self:registerCommand("markdown:internal:captioned-table", function (options, content)
    -- Makes it easier for class/packages to provide their own captioned-table
    -- environment if they want to do so (possibly with more features,
    -- e.g. managing list of tables, numbering and cross-references etc.),
    -- while minimally providing a default fallback solution.
    if not SILE.Commands["captioned-table"] then
      SILE.call("markdown:fallback:captioned-table", {}, content)
    else
      local tableopts = {}
      if hasClass(options, "unnumbered") then
        tableopts.numbering = false
      end
      if hasClass(options, "notoc") then
        tableopts.toc = false
      end
      SILE.call("captioned-table", tableopts, content)
    end
  end, "Captioned table in Markdown (internal)")

  self:registerCommand("markdown:internal:captioned-figure", function (options, content)
    -- Makes it easier for class/packages to provide their own captioned-figure
    -- environment if they want to do so (possibly with more features,
    -- e.g. managing list of tables, numbering and cross-references etc.),
    -- while minimally providing a default fallback solution.
    if not SILE.Commands["captioned-figure"] then
      SILE.call("markdown:fallback:captioned-figure", {}, content)
    else
      local figopts = {}
      if hasClass(options, "unnumbered") then
        figopts.numbering = false
      end
      if hasClass(options, "notoc") then
        figopts.toc = false
      end
      SILE.call("captioned-figure", figopts, content)
    end
  end, "Captioned figure in Markdown (internal)")

  self:registerCommand("markdown:internal:codeblock", function (options, content)
    local render = SU.boolean(options.render, true)
    if render and hasClass(options, "dot") then
      local handler = SILE.rawHandlers["embed"]
      if not handler then
        -- Shouldn't occur since we loaded the embedders package
        SU.error("No inline handler for image embedding")
      end
      options.format = options.class
      handler(options, content)
    elseif render and hasClass(options, "djot") then
      SILE.processString(SU.contentToString(content), "djot", nil, options)
    elseif render and hasClass(options, "markdown") then
      SILE.processString(SU.contentToString(content), "markdown", nil, options)
    elseif hasClass(options, "lua") then
      -- Naive syntax highlighting for Lua, until we have a more general solution
      local tree = {}
      if options.id then
        tree[#tree+1] = createCommand("label", { marker = options.id })
      end
      local toks = pl.lexer.lua(content[1], {})
      for tag, v in toks do
        local out = tostring(v)
        if tag == "string" then
          -- rebuild string quoting...
          out = out:match('"') and ("'"..out.."'") or ('"'..out..'"')
        end
        if naiveLuaCodeTheme[tag] then
          local cascade = CommandCascade()
          if naiveLuaCodeTheme[tag].color then
            cascade:call("color", { color = naiveLuaCodeTheme[tag].color })
          end
          if naiveLuaCodeTheme[tag].bold then
            cascade:call("strong", {})
          end
          if naiveLuaCodeTheme[tag].italic then
            cascade:call("em", {})
          end
          tree[#tree+1] = cascade:tree({ out })
        else
          tree[#tree+1] = SU.utf8charfromcodepoint("U+200B")..out -- HACK with ZWSP to trick the typesetter respecting standalone linebreaks
        end
      end
      SILE.call("verbatim", {}, tree)
    else
      -- Just raw unstyled verbatim
      SILE.call("verbatim", {},
        options.id and {
          createCommand("label", { marker = options.id }),
          subContent(content)
        } or {
          subContent(content)
        }
      )
    end
    SILE.call("smallskip")
  end, "(Fenced) code block in Markdown (internal)")

  self:registerCommand("markdown:internal:lineblock", function (_, content)
    SILE.call("smallskip")
    for _, v in ipairs(content) do
      if v.command == "v" then
        SILE.call("markdown:internal:paragraph", {}, v)
      else -- stanza
        SILE.call("smallskip")
      end
    end
    SILE.call("smallskip")
  end, "Default line block in Markdown (internal)")

  self:registerCommand("markdown:internal:math", function (options, content)
    local mode = options.mode or "text"
    -- NOTE: The following doesn't work: SILE.call("math", {}, content)
    -- Let's go for a lower-level AST construct instead.
    SILE.process({
      createCommand("math", { mode = mode }, SU.contentToString(content))
    })
  end)

  self:registerCommand("markdown:internal:nbsp", function (options, _)
    -- Normally an inter-word non-breakable space is stretchable/shrinkable, with
    -- the same rules as a regular space. That's good typography, but some people
    -- may complain about it, so let's have a setting for overrinding it.
    -- (And with Djot, we can attach attributes to any content, so why not have a
    -- pseudo-class attribute there too.)
    local fixed = hasClass(options, "fixed") or SILE.settings:get("markdown.fixednbsp")
    local widthsp = SILE.shaper:measureSpace(SILE.font.loadDefaults({}))
    if fixed then
      SILE.call("kern", { width = widthsp.length })
    else
      SILE.call("kern", { width = widthsp })
    end
  end, "Inserts a non-breakable inter-word space (internal)")

  self:registerCommand("markdown:internal:captioned-blockquote", function (options, content)
    if type(content) ~= "table" then
      SU.error("Expected a table AST content in captioned blockquote environment")
    end
    local title = removeFromTree(content, "caption")

    if SILE.Commands["epigraph"] then -- asssuming the implementation from resilient.epigraph.
      if title then
        -- Trick: Put the extract title back as "\source"
        title.command = "source"
        content[#content+1] = title
      end
      SILE.call("epigraph", options, content)
    else
      SU.warn([[Apparently, you are not using a resilient class.
Quotation captions are ignored.
Please consider using a resilient-compatible class!]])
      SILE.call("markdown:internal:blockquote", options, content)
    end
  end, "Captioned blockquote in Djot (internal)")

  self:registerCommand("markdown:internal:toc", function (options, _)
    if not SILE.Commands["tableofcontents"] then
      SU.warn("No table of contents command available (skipped)")
      return
    end
    local tocHeaderCmd = SILE.Commands["tableofcontents:header"]
    if tocHeaderCmd then
      -- HACK (opinionated)
      -- By design, resilient.tableofcontents does not output a header.
      -- In case the standard tableofcontents package from the SILE core
      -- distribution is used, then we temporarily cancel its header,
      -- so we get the same behavior in whatever case.
      SILE.Commands["tableofcontents:header"] = function () end
    end
    SILE.call("tableofcontents", options)
    SILE.Commands["tableofcontents:header"] = tocHeaderCmd
  end, "Table of contents in Djot (internal)")

  self:registerCommand("markdown:internal:defn", function (options, content)
    -- Makes it easier for class/packages to provide their own definition
    -- environment if they want to do so (possibly with more features),
    -- while minimally providing a default fallback solution.
    if not SILE.Commands["defn"] then
      SILE.call("markdown:fallback:defn", {}, content)
    else
      SILE.call("defn", options, content)
    end
  end, "Definition item in Markdown (internal)")

  -- B. Fallback commands

  self:registerCommand("markdown:fallback:blockquote", function (_, content)
    SILE.call("smallskip")
    SILE.typesetter:leaveHmode()
    SILE.settings:temporarily(function ()
      local indent = SILE.measurement("2em"):absolute()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width + indent))
      SILE.settings:set("document.rskip", SILE.nodefactory.glue(rskip.width + indent))
      SILE.settings:set("font.size", SILE.settings:get("font.size") * 0.95)
      SILE.process(content)
      SILE.typesetter:leaveHmode()
    end)
    SILE.call("smallskip")
  end, "A fallback blockquote environment if 'blockquote' does not exist")

  self:registerCommand("markdown:fallback:header", function (_, content)
    SILE.typesetter:leaveHmode(1)
    SILE.call("goodbreak")
    SILE.call("smallskip")
    SILE.call("noindent")
    SILE.call("font", { weight = 700 }, content)
    SILE.call("novbreak")
    SILE.call("par")
    SILE.call("novbreak")
  end, "A fallback default header if none exists for the requested sectioning level")

  self:registerCommand("markdown:fallback:captioned-table", function (_, content)
    if type(content) ~= "table" then
      SU.error("Expected a table AST content in captioned table environment")
    end
    local caption = removeFromTree(content, "caption")

    SILE.process(content)
    if caption then
      SILE.call("novbreak")
      SILE.call("font", {
        size = SILE.settings:get("font.size") * 0.95
      }, function ()
        SILE.call("center", {}, caption)
      end)
    end
    SILE.call("smallskip")
  end, "A fallback command for Markdown to insert a captioned table")

  self:registerCommand("markdown:fallback:defn", function (_, content)
    if type(content) ~= "table" then
      SU.error("Expected a table AST content in captioned table environment")
    end
    local term = removeFromTree(content, "term")
    local desc = removeFromTree(content, "desc")

    SILE.typesetter:leaveHmode()
    SILE.call("strong", {}, term)
    SILE.call("novbreak")
    SILE.settings:temporarily(function ()
      local indent = SILE.measurement("2em"):absolute()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width + indent))
      SILE.process(desc)
      SILE.typesetter:leaveHmode()
    end)
    SILE.call("smallskip")
  end, "A fallback command for Markdown to insert a definition item (term, desc)")

  self:registerCommand("markdown:fallback:captioned-figure", function (_, content)
    if type(content) ~= "table" then
      SU.error("Expected a table AST content in captioned figure environment")
    end
    local caption = removeFromTree(content, "caption")

    SILE.call("smallskip")
    SILE.call("center", {}, function ()
      SILE.process(content)
      if caption then
        SILE.call("novbreak")
        SILE.call("font", {
          size = SILE.settings:get("font.size") * 0.95
        }, caption)
      end
    end)
    SILE.call("smallskip")
  end, "A fallback command for Markdown to insert a captioned figure")

  -- C. Customizable hooks

  self:registerCommand("markdown:custom-style:hook", function (options, content)
    -- Default implementation for the custom-style hook:
    -- If we are in the context of a resilient-compatible class and there's
    -- an existing style going by that name, use it.
    -- Otherwise, tf there is a corresponding SILE command, we invoke it.
    -- otherwise, we just ignore the style and process the content.
    -- It allows us, e.g. to already
    --  - Use resilient styles in proper context
    --  - Use some interesting commands, such as "custom-style=raggedleft".
    -- Package or class designers MAY override this hook to support any other
    -- styling mechanism they may have or want.
    -- The available options are the custom-style "name" and a "scope" which
    -- can be "inline" (for inline character-level styling) or "block" (for
    -- block paragraph-level styling).
    local name = SU.required(options, "name", "markdown custom style hook")
    if self.isResilient
      and self.class.packages["resilient.styles"]
        -- HACK TODO we'd need a self.class.packages["resilient.styles"]:hasStyle(name)
        -- to avoid tapping into internal structures.
        -- self.class.packages["resilient.styles"]:resolveStyle(name, true) returns
        -- {} for a (discardable) non-existing style, so is not very handy here.
        and SILE.scratch.styles.specs[name] then
      if options.scope == "block" then
        SILE.call("style:apply:paragraph", { name = name }, content)
      else
        SILE.call("style:apply", { name = name }, content)
      end
    elseif SILE.Commands[name] then
      SILE.call(name, {}, content)
    else
      SILE.process(content)
      if options.scope == "block" then
        SILE.call("par")
      end
    end
  end, "Default hook for custom style support in Markdown")

end

package.documentation = [[\begin{document}
A helper package for Markdown processing, providing common hooks and fallback commands.

It is not intended to be used alone.
\end{document}]]

return package
