--
-- Common commands for Markdown support in SILE, when there is no
-- direct mapping to existing commands or packages.
--
-- License: MIT (c) 2022 Omikhleia
--
-- Split in a standalone package so that it can be reused and
-- generalized somewhat independently from the undelying parsing code.
--
local utils = require("packages.markdown.utils")
local base = require("packages.base")

local package = pl.class(base)
package._name = "markdown.commands"

-- A small utility class that allows wrapping commands applied to a
-- content, avoiding a callback hell with conditionals where it is
-- used and providing a sequence-oriented presentation.
local CommandCascade = pl.class({
  wrapper = nil,
  call = function (self, command, options)
    local inner = self.wrapper
    if inner then
      self.wrapper = function (content)
        SILE.call(command, options, function ()
          inner(content)
        end)
      end
    else
      self.wrapper = function (content)
        SILE.call(command, options, content)
      end
    end
  end,
  process = function (self, content)
    if not self.wrapper then
      SILE.process(content)
    else
      self.wrapper(content)
    end
  end,
})

local UsualSectioning = { "chapter", "section", "subsection", "subsubsection" }
local function getSectioningCommand (level)
  if level <= #UsualSectioning then
    -- Check we actually have those commands (e.g. some classes might not
    -- have subsubsections.)
    if SILE.Commands[UsualSectioning[level]] then
      return UsualSectioning[level]
    end
    SU.warn("Unknown command \\"..UsualSectioning[level].." (fallback to a default generic header)")
    -- Default to something anyway.
    return "markdown:fallback:header"
  end
  -- Also default to something anyway, but different message
  SU.warn("No support found for heading level "..level.." (fallback to a default generic header)")
  return "markdown:fallback:header"
end

local extractFromTree = function (tree, command)
  for i = 1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return table.remove(tree, i)
    end
  end
end

local function hasClass (options, classname)
  -- N.B. we want a true boolean here
  if options.class and string.match(' ' .. options.class .. ' ',' '..classname..' ') then
    return true
  end
  return false
end

local function hasLinkContent(ast)
  if type(ast) == "table" then
    return #ast > 1 or hasLinkContent(ast[1])
  end
  if type(ast) == "string" and ast ~= "" then
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
      t[#t+1] = utils.createCommand("markdown:internal:decimal", {}, token.separator)
    end
  end
  return t
end

function package:_init (_)
  base._init(self)
  -- Only load low-level packages (= utilities)
  -- The claas should be responsible for loading the appropriate higher-level
  -- constructs, see fallback commands further below for more details.
  self.class:loadPackage("color")
  self.class:loadPackage("image")
  self.class:loadPackage("inputfilter")
  self.class:loadPackage("labelrefs")
  self.class:loadPackage("lists")
  self.class:loadPackage("math")
  self.class:loadPackage("ptable")
  self.class:loadPackage("rules")
  self.class:loadPackage("smartquotes")
  self.class:loadPackage("svg")
  self.class:loadPackage("textsubsuper")
  self.class:loadPackage("url")

  -- Optional packages
  pcall(function () return self.class:loadPackage("couyards") end)
end

function package:hasCouyards ()
  return self.class.packages["couyards"]
end

function package:registerCommands ()
  -- A. Commands (normally) intended to be used by this package only.

  self:registerCommand("markdown:internal:paragraph", function (_, content)
    -- Implicit figure: "An image with nonempty alt text, occurring by itself in a paragraph,
    -- will be rendered as a figure with a caption. The image???s alt text will be used as the
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
        SILE.call("markdown:internal:captioned-figure", {}, {
          image,
          utils.createCommand("caption", {}, {
            utils.createCommand("label", { marker = id }),
            caption,
          }),
        })
      else
        SILE.call("markdown:internal:captioned-figure", {}, {
          image,
          utils.createCommand("caption", {}, caption),
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

  self:registerCommand("markdown:internal:hrule", function (options, _)
    if options.separator == "***" then
      SILE.call("center", {}, { "???" }) -- Asterism
    elseif options.separator == "* * *" then
      SILE.call("center", {}, { "*???*???*" }) -- Dinkus (with em-spaces)
    elseif options.separator == "---" then
        SILE.call("center", {}, function ()
          SILE.call("raise", { height = "0.5ex" }, function ()
            SILE.call("hrule", { width = "20%lw" })
        end)
      end)
    elseif options.separator == "----" then
      SILE.call("center", {}, function ()
        SILE.call("raise", { height = "0.5ex" }, function ()
          SILE.call("hrule", { width = "33%lw" })
        end)
      end)
    elseif options.separator == "- - - -" and self:hasCouyards() then
      SILE.call("smallskip")
      SILE.call("couyard", { type = 6, width = "default" })
    elseif options.separator == "--------------" then -- Page break
      SILE.call("eject")
    else
      SILE.call("fullrule")
    end
  end, "Horizontal rule in Markdown (internal)")

  self:registerCommand("markdown:internal:header", function (options, content)
    local level = SU.required(options, "level", "header")
    local command = getSectioningCommand(SU.cast("integer", level))
    local numbering = not hasClass(options, "unnumbered")
    SILE.call(command, { numbering = numbering }, content)
    if options.id then
      -- HACK.
      -- Somewhat messy. If done before the sectioning, it could end on the
      -- previous page. Within its content, it breaks as TOC entries want
      -- a table content, so we can't use a function above...
      -- We are left with doing it after, but that's not perfect either vs.
      -- page breaks and indent/noindent...
      -- In the resilient.book class, I added a marker option to sections and
      -- reimplemented that part, but here we work with what we have...
      SILE.call("label", { marker = options.id })
    end
  end, "Header in Markdown (internal)")

  self:registerCommand("markdown:internal:term", function (_, content)
    SILE.typesetter:leaveHmode()
    SILE.call("font", { weight = 600 }, content)
  end, "Definition list term in Markdown (internal)")

  self:registerCommand("markdown:internal:definition", function (_, content)
    SILE.typesetter:leaveHmode()
    SILE.settings:temporarily(function ()
      local indent = SILE.measurement("2em"):absolute()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width + indent))
      SILE.process(content)
      SILE.typesetter:leaveHmode()
    end)
    SILE.call("smallskip")
  end, "Definition list block in Markdown (internal)")

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
      cascade:call("language", { main = utils.normalizeLang(options.lang) })
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
      cascade:call("language", { main = utils.normalizeLang(options.lang) })
    end
    if hasClass(options, "smallcaps") then
      cascade:call("font", { features = "+smcp" })
    end
    if hasClass(options, "underline") then
      cascade:call("underline")
    end
    if options["custom-style"] then
      -- The style (or the hook) is reponsible for paragraphing
      cascade:call("markdown:custom-style:hook", { name = options["custom-style"], scope = "inline" })
    end
    cascade:process(content)
  end, "Span in Markdown (internal)")

  self:registerCommand("markdown:internal:image", function (options, _)
    local uri = SU.required(options, "src", "image")
    if options.id then
      SILE.call("label", { marker = options.id })
    end
    if utils.getFileExtension(uri) == "svg" then
      SILE.call("svg", options)
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
        SILE.call("href", { src = uri }, content)
      else
        SU.warn("Ignored empty link to target "..uri)
      end
    end
  end, "Link in Markdown (internal)")

  self:registerCommand("markdown:internal:footnote", function (_, content)
    if not SILE.Commands["footnote"] then
      -- The reasons for NOT loading a package for this high-level structure
      -- is that the class or other packages may provide their own implementation
      -- (e.g. formatted differently, changed to endnotes, etc.).
      -- So we only do it as a fallback if mising, to degrade gracefully.
      SU.warn("Trying to enforce fallback for unavailable \\footnote command")
      self.class:loadPackage("footnotes")
    end
    SILE.call("footnote", {}, content)
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
        SILE.call("cr")
      elseif rawtext:match("^<wbr[>/%s]") then
        SILE.call("penalty", { penalty = 100 })
      end
    end
  end, "Raw native inline content in Markdown (internal)")

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

  self:registerCommand("markdown:internal:captioned-table", function (_, content)
    -- Makes it easier for class/packages to provide their own captioned-table
    -- environment if they want to do so (possibly with more features,
    -- e.g. managing list of tables, numbering and cross-references etc.),
    -- while minimally providing a default fallback solution.
    if not SILE.Commands["captioned-table"] then
      SILE.call("markdown:fallback:captioned-table", {}, content)
    else
      SILE.call("captioned-table", {}, content)
    end
  end, "Captioned table in Markdown (internal)")

  self:registerCommand("markdown:internal:captioned-figure", function (_, content)
    -- Makes it easier for class/packages to provide their own captioned-figure
    -- environment if they want to do so (possibly with more features,
    -- e.g. managing list of tables, numbering and cross-references etc.),
    -- while minimally providing a default fallback solution.
    if not SILE.Commands["captioned-figure"] then
      SILE.call("markdown:fallback:captioned-figure", {}, content)
    else
      SILE.call("captioned-figure", {}, content)
    end
  end, "Captioned table in Markdown (internal)")

  self:registerCommand("markdown:internal:codeblock", function (options, content)
    if hasClass(options, "lua") then
      -- Naive syntax highlighting for Lua, until we have a more general solution
      SILE.call("verbatim", {}, function ()
        if options.id then
          SILE.call("label", { marker = options.id })
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
            cascade:process({ out })
          else
            SILE.typesetter:typeset(SU.utf8charfromcodepoint("U+200B")..out) -- HACK with ZWSP to trick the typesetter respecting standalone linebreaks
          end
        end
        SILE.typesetter:leaveHmode()
      end)
    else
      -- Just raw unstyled verbatim
      SILE.call("verbatim", {}, function ()
        if options.id then
          SILE.call("label", { marker = options.id })
        end
        SILE.process(content)
        SILE.typesetter:leaveHmode()
      end)
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
    -- NOTE: Not sure why the following doesn't work!!!!
    -- SILE.call("math", {}, content)
    SILE.processString("\\math[mode="..mode.."]{"..SU.contentToString(content).."}", "sil")
  end)

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
  end, "A fallback default header if none exists for the requested sectioning label")

  self:registerCommand("markdown:fallback:captioned-table", function (_, content)
    if type(content) ~= "table" then
      SU.error("Expected a table AST content in captioned table environment")
    end
    local caption = extractFromTree(content, "caption")

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

  self:registerCommand("markdown:fallback:captioned-figure", function (_, content)
    if type(content) ~= "table" then
      SU.error("Expected a table AST content in captioned figure environment")
    end
    local caption = extractFromTree(content, "caption")

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
  end, "A fallback command for Markdown to insert a captioned table")

  -- C. Customizable hooks

  self:registerCommand("markdown:custom-style:hook", function (options, content)
    -- Default implementation for the custom-style hook:
    -- If there is a corresponding command, we invoke it, otherwise, we just
    -- ignore the style and process the content. It allows us, e.g. to already
    -- use some interesting features, such as "custom-style=raggedleft".
    -- Package or class designers MAY override this hook to support any other
    -- styling mechanism they may have or want.
    -- The available options are the custom-style "name" and a "scope" which
    -- can be "inline" (for inline character-level styling) or "block" (for
    -- block paragraph-level styling).
    local name = SU.required(options, "name", "markdown custom style hook")
    if SILE.Commands[name] then
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
