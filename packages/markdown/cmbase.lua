---A base class for markdown command packages.
--
-- It abstracts the low-level details of feature detection and compatibility with resilient components.
-- So the markdown.command packages can focus on their specific features and commands.
--
-- @copyright License: MIT (c) 2024 Omikhleia, Didier Willis
-- @module packages.markdown.cmbase
--

local base = require("packages.base")

local package = pl.class(base)
package._name = "markdown.cmbase"

-- For feature detection.
-- NOTE: The previous implementation was clever;
--   local ok, ResilientBase = pcall(require, 'classes.resilient.base')
--   return ok and self.class:is_a(ResilientBase)
-- However this *loads* the class, which loads all the silex extensions, even if
-- the class is not actually used...
-- Enforcing the silex extensions is not what we wanted.
-- So we are back to a more naive implementation, checking the class hierarchy
-- by name. This is perhaps lame and knows too much about internals, but heh.
local function isResilientClass (cl)
  while cl do
    if cl._name == "resilient.base" then
      -- The class is a resilient class or derived from one
      return true
    end
    cl = cl._base
  end
  return false
end

--- Load a package with a resilient variant.
---@param resilientpack   string   The resilient package name.
---@param legacypack      string   The legacy package name.
function package:loadAltPackage (resilientpack, legacypack)
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

--- Load an optional package if present
---@param pack  string   The package name.
function package:loadOptPackage (pack)
  local ok, _ = pcall(function () return self:loadPackage(pack) end)
  SU.debug("markdown.commands", "Optional package "..pack.. (ok and " loaded" or " not loaded"))
end

--- Feature detection, so we can see e.g. with self.hasPackageSupport.xxx if
--- a package is supported or not.
---@param check function  The feature detection function.
---@return table          The proxy object.
function package:_createSupportProxy (check)
  return setmetatable({}, {
    __index = check,
    __newindex = function (_, key, _)
      SU.error("Invalid attempt to set a feature detection value: " .. key)
    end,
  })
end

--- Package initialization.
function package:_init (_)
  base._init(self)

  -- Check if document class is a resilient class or derived from one
  self.isResilient = isResilientClass(self.class)
  SU.debug("markdown.commands", "Feature detection:",
    self.isResilient and "used in a resilient class" or "used in a non-resilient class")

  self.hasPackageSupport = self:_createSupportProxy(function (_, name)
    local pack = self.class.packages[name]
    SU.debug("markdown.commands", "Feature detection: package", name,
      pack and "supported" or "not supported")
    return pack
  end)

  self.styles = self.hasPackageSupport["resilient.styles"]
  if self.styles then
    SU.debug("markdown.commands", "Feature detection: registering custom styles")
    self:registerStyles()
  end

  self.hasCommandSupport = self:_createSupportProxy(function (_, name)
    -- Checking low-level SILE internals is not that nice...
    -- SILE was refactor to have loadPackage() etc. methods, a lot of boilerplate
    -- if at the end we still need to tap into low-level internals.
    local cmd = SILE.Commands[name]
    SU.debug("markdown.commands", "Feature detection: command", name,
      cmd and "supported" or "not supported")
    return cmd
  end)

  self.hasStyleSupport = self:_createSupportProxy(function (_, name)
    local style = self.isResilient and self.styles
      --and self.styles:hasStyle(name)
      -- TODO A hasStyle(name) method would be nice to have in resilient.styles
      -- to avoid tapping into internal structures.
      -- The resolveStyle(name, true) method returns {} for a (discardable)
      -- non-existing style, so is not very handy here.
      -- But it's a chicken and egg problem, between resilient and us.
      and SILE.scratch.styles.specs[name] -- HACK
    SU.debug("markdown.commands", "Feature detection: style", name,
      style and "supported" or "not supported")
    return style
  end)
end

function package:registerCommand(name, func, help, pack)
  local tweakCommandWithKnownOptions = function (options, content)
    options = options or {}
    -- Tweak known options to be compatible with SILE units.
    -- width and height in percentage are replaced by line and frame relative
    -- units, respectively.
    if options.width and type(options.width) == "string" then
      options.width = options.width:gsub("%%$", "%%lw")
    end
    if options.height and type(options.height) == "string" then
      options.height = options.height:gsub("%%$", "%%fh")
    end
    return func(options, content)
  end
  base.registerCommand(self, name, tweakCommandWithKnownOptions, help, pack)
end

--- Register a style (as in resilient packages).
function package:registerStyle (name, opts, styledef)
  return self.styles:defineStyle(name, opts, styledef, self._name)
end

--- Register styles (as in resilient packages)
--- For overriding in subclass
function package.registerStyles (_) end

package.documentation = [[\begin{document}
A base package class for \code{markdown.commands}, hiding the low-level details of feature detection and compatibility with resilient components.

It is not intended to be used alone.
\end{document}]]

return package
