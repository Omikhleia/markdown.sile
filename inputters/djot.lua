--- Djot native inputter for SILE
--
-- Using the djot Lua library for parsing.
-- Reusing the common commands initially made for the "markdown" inputter/package.
--
-- @copyright License: MIT (c) 2023 Omikhleia
-- @module inputters.djot
--
local utils = require("packages.markdown.utils")

-- DJOT AST CONVERTER TO SILE AST

local djotast = require("djot.ast")

local Renderer = pl.class()

function Renderer:_init()
  self.references = {}
  self.footnotes = {}
  self.metadata = {}
  self.tight = false -- We do use it currently, though!
end

function Renderer:render(doc)
  self.references = doc.references
  self.footnotes = doc.footnotes
  return self[doc.t](self, doc)
end

function Renderer:render_children(node)
  -- trap stack overflow
  local out = {}
  local ok, err = pcall(function ()
    if node.c and #node.c > 0 then
      local oldtight
      if node.tight ~= nil then
        oldtight = self.tight
        self.tight = node.tight
      end
      for i=1,#node.c do
        out[#out+1] = self[node.c[i].t](self, node.c[i])
      end
      if node.tight ~= nil then
        self.tight = oldtight
      end
    end
  end)
  if not ok then
    if err:find("stack overflow") then
      SU.warn("DJOT: DEEPLY NESTED CONTENT OMITTED")
    else
      SU.error(err)
    end
  end
  --  Simplify output by removing useless grouping
  if type(out) == "table" and #out == 1 and not out.command then
    out = out[1]
  end
  return out
end

function Renderer:doc(node)
  return self:render_children(node)
end

function Renderer.raw_block (_, node)
  return utils.createCommand("markdown:internal:rawblock", { format = node.format }, node.s)
end

function Renderer:para (node)
  if #node.c == 1 and node.c[1].t == "symbol" then
    node.c[1]._standalone_ = true
  end

  local content = self:render_children(node)
  -- interpret as a div when containing attributes
  if node.attr then
    return utils.createCommand("markdown:internal:div", node.attr, content)
  end
  return utils.createCommand("markdown:internal:paragraph", {}, content)
end

function Renderer:blockquote (node)
  local content = self:render_children(node)
  local out = utils.createCommand("markdown:internal:blockquote", {}, content)
  if node.attr then
    -- Add a div when containing attributes
    return utils.createCommand("markdown:internal:div", node.attr, out)
  end
  return out
end

function Renderer:div (node)
  local options = node.attr or {}
  local content = self:render_children(node)
  return utils.createCommand("markdown:internal:div" , options, content)
end

function Renderer:section (node)
  self.currentid = node.attr and node.attr.id
  local content = self:render_children(node)
  return content
end

function Renderer:heading (node)
  local options = node.attr or {}
  local content = self:render_children(node)
  options.id = self.currentid
  options.level = node.level
  return utils.createCommand("markdown:internal:header", options, content)
end

function Renderer.thematic_break (_, node)
  local options = node.attr or {}
  return utils.createCommand("markdown:internal:thematicbreak", options)
end

function Renderer.code_block (_, node)
  local options = node.attr or {}
  options.class = node.lang and ((options.class and (options.class.." ") or "") .. node.lang) or options.class
  return utils.createCommand("markdown:internal:codeblock", options, node.s)
end

function Renderer:table (node)
  local options = node.attr or {}
  if not node.c then
    SU.error("Table without content (should not occur)")
  end
  -- extract caption, check rows
  local rows = {}
  local caption
  for _, v in ipairs(node.c) do
    if v.t == "caption" then
      caption = self:render_children(v)
    elseif v.t == "row" then
      rows[#rows+1] = v
    else
      SU.error("Unexpected element in table: "..v.t)
    end
  end
  node.c = rows

  local row = rows[1]
  local numberOfCols = #row.c
  local cWidth = {}
  for i = 1, numberOfCols do
    -- Currently we make all columns the same width, with the table taking
    -- a full line width. Well, nearly full: 99.9% to avoid 100% which
    -- causes issues in SILE flushed/centered environments, but this is
    -- deemed acceptable (hardly visible, and in most case we have some
    -- rounding anyway with the number format, so we aren't really making
    -- things worse).
    -- N.B. For future consideration: in Djot we could use a table attribute
    -- for specifying the target width. This would however require some
    -- changes to the ptable implementation, though...
    cWidth[i] = string.format("%.5f%%lw", 99.9 / numberOfCols)
  end
  local ptable = utils.createStructuredCommand("ptable", {
     cols = table.concat(cWidth, " "),
     header = SU.boolean(row.head, false),
  }, self:render_children(node))

  if not caption then
    return ptable
  end
  local captioned = {
    ptable,
    utils.createCommand("caption", {}, caption)
  }
  return utils.createStructuredCommand("markdown:internal:captioned-table", options, captioned)
end

function Renderer:row (node)
  local options = {}
  local content = self:render_children(node)
  options.background = node.head and "#eee"
  return utils.createStructuredCommand("row", options, content)
end

function Renderer:cell (node)
  local options = {}
  local content = self:render_children(node)
  options.halign = node.align
  return utils.createStructuredCommand("cell", options, content)
end

function Renderer.caption (_, _)
  -- Extracted at table processing, so we should not enter this method.
  SU.error("Should not be invoked")
end

local listStyle = {
  ["1"] = "arabic",
  I = "Roman",
  i = "roman",
  A = "Alpha",
  a = "alpha",
}

function Renderer:list (node)
  local sty = node.style
  if sty == "*" or sty == "+" or sty == "-" then
    local content = self:render_children(node)
    for i = 1, #content do
      if content[i].command ~= "item" then
        content[i] = utils.createCommand("item", {}, content[i])
      end
    end
    return utils.createStructuredCommand("itemize", {}, content)
  end

  if sty == "X" then
    local content = self:render_children(node)
    for i = 1, #content do
      if content[i].command ~= "item" then
        content[i] = utils.createCommand("item", {}, content[i])
      end
    end
    return utils.createStructuredCommand("itemize", {}, content)
  end

  if sty == ":" then
    local content = self:render_children(node)
    return utils.createStructuredCommand("markdown:internal:paragraph", {}, content)
  end

  -- Enumerate
  local a = node.style:sub(1,1)
  local b = node.style:sub(-1)
  local options = {
    start = node.start,
  }
  if a:match("%p") then
    options.before = a
  end
  if b:match("%p") then
    options.after = b
  end
  local list_type = node.style:gsub("%p", "")
  options.display = listStyle[list_type]

  local content = self:render_children(node)
  for i = 1, #content do
    if content[i].command ~= "item" then
      content[i] = utils.createCommand("item", {}, content[i])
    end
  end
  return utils.createStructuredCommand("enumerate", options, content)
end

function Renderer:list_item (node)
  local options = {}
  local bullet = ((node.checkbox == "checked") and "☑")
    or ((node.checkbox == "unchecked") and "☐")
  options.bullet = bullet

  local content = self:render_children(node)
  return utils.createCommand("item", options, content)
end

function Renderer:term (node)
  local content = self:render_children(node)
  return utils.createCommand("markdown:internal:term", {}, content)
end

function Renderer:definition (node)
  local content = self:render_children(node)
  return utils.createCommand("markdown:internal:definition", {}, content)
end

function Renderer:definition_list_item (node)
  return self:render_children(node)
end

function Renderer.reference_definition (_)
  SU.warn("Reference definition issue")
  return "¤(def ref)" -- TODO, I didn't get why the HTML renderer had this.
end

function Renderer:footnote_reference (node)
  local label = node.s
  local node_footnote = self.footnotes[label]
  if not node_footnote then
    SU.error("Failure to find footnote '"..label.."'")
  end
  local content = self:render_children(node_footnote)
  return utils.createCommand("markdown:internal:footnote", {}, content)
end

function Renderer.raw_inline (_, node)
  return utils.createCommand("markdown:internal:rawinline", { format = node.format }, node.s)
end

function Renderer.str (_, node)
  if node.attr then
    -- add a span, if needed, to contain attribute on a bare string:
    return utils.createCommand("markdown:internal:span" , node.attr, node.s)
  end
  return node.s
end

function Renderer.softbreak (_)
  return " "
end

function Renderer.hardbreak (_)
  return utils.createCommand("cr")
end

function Renderer.nbsp (_, node)
  local options = node.attr or {}
  return utils.createCommand("markdown:internal:nbsp", options)
end

function Renderer.verbatim (_, node)
  -- TODO options/attrs... but we need more work on pandocast/markdown and a replacement for \code
  local options = {}
  return utils.createCommand("code", options, node.s)
end

function Renderer:link (node)
  local content = self:render_children(node)
  local options = djotast.new_attributes{}
  if node.reference then
    local ref = self.references[node.reference]
    if ref then
      if ref.attr then
        djotast.copy_attributes(options, ref.attr)
      end
      djotast.insert_attribute(options, "src", ref.destination)
    end
  elseif node.destination then
    djotast.insert_attribute(options, "src", node.destination)
  end
  -- link's attributes override reference's:
  djotast.copy_attributes(options, node.attr)
  return utils.createCommand("markdown:internal:link", options, content)
end

Renderer.url = Renderer.link

Renderer.email = Renderer.link

function Renderer:image (node)
  local content = self:render_children(node)
  local options = djotast.new_attributes{}
  if node.reference then
    local ref = self.references[node.reference]
    if ref then
      if ref.attr then
        djotast.copy_attributes(options, ref.attr)
      end
      djotast.insert_attribute(options, "src", ref.destination)
    end
  elseif node.destination then
    djotast.insert_attribute(options, "src", node.destination)
  end
  -- image's attributes override reference's:
  djotast.copy_attributes(options, node.attr)
  return utils.createCommand("markdown:internal:image", options, content)
end

function Renderer:span (node)
  local options = node.attr or {}
  local content = self:render_children(node)
  return utils.createCommand("markdown:internal:span" , options, content)
end

function Renderer:mark (node)
  SU.warn("Djot mark (highlight) is not fully implemented") -- See HACK
  local content = self:render_children(node)
  local out = utils.createCommand("color", { color = "red" }, content) -- HACK
  if node.attr then
    -- Add a div when containing attributes
    return utils.createCommand("markdown:internal:span", node.attr, out)
  end
  return out
end

function Renderer:insert (node)
  local content = self:render_children(node)
  local out = { "⟨", content, "⟩" }
  if node.attr then
    -- Add a div when containing attributes
    return utils.createCommand("markdown:internal:span", node.attr, out)
  end
  return out
end

function Renderer:delete (node)
  local content = self:render_children(node)
  local out = { "{", content, "}" }
  if node.attr then
    -- Add a div when containing attributes
    return utils.createCommand("markdown:internal:span", node.attr, out)
  end
  return out
end

local function extractAttrValue (attr, key)
  if not attr then
    return nil, false
  end
  local value = attr[key]
  attr[key] = nil
  local n = 0
  for _ in pairs(attr) do
    n = n + 1
  end
  return value, n > 0
end

function Renderer:subscript (node)
  local content = self:render_children(node)
  local fake, hasOtherAttrs = extractAttrValue(node.attr, "fake")
  local out = utils.createCommand("textsubscript", { fake = fake }, content)
  if hasOtherAttrs then
    -- Add a span when containing other attributes
    return utils.createCommand("markdown:internal:span", node.attr, out)
  end
  return out
end

function Renderer:superscript (node)
  local content = self:render_children(node)
  local fake, hasOtherAttrs = extractAttrValue(node.attr, "fake")
  local out = utils.createCommand("textsuperscript", { fake = fake }, content)
  if hasOtherAttrs then
    -- Add a span when containing other attributes
    return utils.createCommand("markdown:internal:span", node.attr, out)
  end
  return out
end

function Renderer:emph (node)
  local content = self:render_children(node)
  if node.attr then
    -- Add a span for attributes
    -- Applied first before the font change, so that font-specific attributes
    -- are applied in the right context (e.g. .underline)
    content = utils.createCommand("markdown:internal:span" , node.attr, content)
  end
  return utils.createCommand("em", {}, content)
end

function Renderer:strong (node)
  local content = self:render_children(node)
  if node.attr then
    -- Add a span for attributes
    -- Applied first before the font change, so that font-specific attributes
    -- are applied in the right context (e.g. .underline)
    content = utils.createCommand("markdown:internal:span" , node.attr, content)
  end
  return utils.createCommand("strong", {}, content)
end

function Renderer:double_quoted (node)
  local content = self:render_children(node)
  content = utils.createCommand("doublequoted", {}, content)
  if node.attr then
    -- Add a span for attributes
    -- Applied after, so as to encompass the quotes.
    -- That's probably the expectation, so e.g. "text"{lang=fr} will use French
    -- primary quotations marks.
    content = utils.createCommand("markdown:internal:span" , node.attr, content)
  end
  return content
end

function Renderer:single_quoted (node)
  local content = self:render_children(node)
  content = utils.createCommand("singlequoted", {}, content)
  if node.attr then
    -- Add a span for attributes
    -- Applied after, so as to encompass the quotes.
    -- That's probably the expectation, so e.g. 'text'{lang=fr} will use French
    -- secondary quotations marks.
    content = utils.createCommand("markdown:internal:span" , node.attr, content)
  end
  return content
end

function Renderer.left_double_quote (_)
  return("“")
end

function Renderer.right_double_quote (_)
  return("”")
end

function Renderer.left_single_quote (_)
  return("‘")
end

function Renderer.right_single_quote (_)
  return("’")
end

function Renderer.ellipses (_)
  return("…")
end

function Renderer.em_dash (_)
  return("—")
end

function Renderer.en_dash (_)
  return("–")
end

function Renderer:symbol (node)
  -- Let's look at fake footnotes to resolve the symbol.
  -- We just added unforeseen templating and recursive variable substitution to Djot.
  local label = ":" .. node.alias .. ":"
  local node_fake_metadata = self.footnotes[label]
  if not node_fake_metadata then
    SU.warn("Symbol '" .. node.alias .. "' was not expanded (no corresponding metadata found)")
    -- TODO Let's not error, but what else could we do with these funny symbols?
    -- Oh oh oh... Don't get me started... Nah you are not ready yet for more tricks...
    local text = ":" .. node.alias .. ":"
    if node.attr then
      -- Add a span for attributes
      return utils.createCommand("markdown:internal:span" , node.attr, text)
    end
    return text
  end

  if #node_fake_metadata.c > 1 and not node._standalone_ then
    SU.error("Cannot use multi-paragraph metatada "..label.." as inline content")
  end

  local content
  if self.metadata[label] then -- use memoized
    content = self.metadata[label]
  else
    if #node_fake_metadata.c == 1 and node_fake_metadata.c[1].t == "para" then
      -- Skip a single para node.
      content = self:render_children(node_fake_metadata.c[1])
    else
      content = self:render_children(node_fake_metadata)
    end
    self.metadata[label] = content -- memoize
  end
  if node.attr then
    if not node._standalone_ then
      -- Add a span for attributes on the inline variant.
      content = utils.createCommand("markdown:internal:span" , node.attr, content)
    else
      -- Those should rather come from the paragraph
      SU.warn("Attributes ignored on block-like symbol '" .. node.alias .. "'")
    end
  end
  return content
end

function Renderer.math (_, node)
  local mode = "text"
  if string.find(node.attr.class, "display") then
    mode = "display"
  end
  return utils.createCommand("markdown:internal:math" , { mode = mode }, { node.s })
end

-- SILE INPUTTER LOGIC

local base = require("inputters.base")

local inputter = pl.class(base)
inputter._name = "djot"
inputter.order = 2

function inputter.appropriate (round, filename, _)
  if round == 1 then
    return filename:match("dj$")
  end
  -- No other round supported...
  return false
end

function inputter.parse (_, doc)
  local djot = require("djot")
  local ast = djot.parse(doc)
  local renderer = Renderer()
  local tree = renderer:render(ast)

  -- The "writer" returns a SILE AST.
  -- Wrap it in a document structure so we can just process it, and if at
  -- root level, load a (default) support class.
  tree = { { tree,
             command = "document", options = { class = "markdown" },
             lno = 0, col = 0, -- For SILE 0.14.5 (issue https://github.com/sile-typesetter/sile/issues/1637)
  } }
  return tree
end

return inputter
