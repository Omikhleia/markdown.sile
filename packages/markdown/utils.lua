--- A few utilities for the markdown / pandocast inputters
--
--
require("silex.ast") -- Compatibility layer
local createCommand = SU.ast.createCommand

--- Some utility functions.
-- @section utils

--- Extract the extension from a file name
-- Assumes a POSIX-compliant name (with a slash as path separators).
--
-- tparam  string fname file name
-- treturn string file extension
local function getFileExtension (fname)
  return fname:match("[^/]+$"):match("[^.]+$")
end

local function nbspFilter (str)
  -- Non-breakable space extraction from a string, replacing them with an
  -- appropriate non-breakable inter-word space.
  local t = {}
  for token in SU.gtoke(str, " ") do -- Warning, U+00A0 here.
    if(token.string) then
      t[#t+1] = token.string
    else
      t[#t+1] = createCommand("markdown:internal:nbsp")
    end
  end
  -- Returns a string or a (SILE AST) table
  if #t == 0 then return "" end
  return #t == 1 and t[1] or t
end

--- Check if a given class is present in the options.
---@param options table    Command options
---@param classname string Pseudo-class specifier
---@return boolean
local function hasClass (options, classname)
  -- N.B. we want a true boolean here
  if options.class and string.match(' ' .. options.class .. ' ',' '..classname..' ') then
    return true
  end
  return false
end

--- Find the first raw handler suitable for the given pseudo-class attributes.
---@param options table  Command options
---@return function|nil  Handler function (if found)
local function hasRawHandler (options)
  for name, handler in pairs(SILE.rawHandlers) do
    if hasClass(options, name) then
      SU.debug("markdown", "Found a raw handler for", name)
      return handler
    end
  end
  return nil
end

--- Find the first embedder suitable for the given pseudo-class attributes.
---@param options table           Command options with class attribute (nil or list of comma-separated classes)
---@return string|nil, function   Embedder name and handler function (if found)
local function hasEmbedHandler (options)
  if not options.class then
    return nil
  end
  local handler = SILE.rawHandlers["embed"]
  if not handler then
    -- Shouldn't occur since we loaded the embedders package
    -- but let's play safe...
    return nil
  end
  -- HACK TODO: Use of a scratch variable is ugly, tapping into the
  -- internals of the embedders package.
  local embedders = SILE.scratch.embedders
  if not embedders then
    return nil
  end
  local classes = pl.stringx.split(options.class, " ")
  for _, name in ipairs(classes) do
    SU.debug("markdown", "Checking for embedder", name)
    if embedders[name] then
      -- NOTE: Accessing the embedder table causes the entry to be loaded
      -- if it exists and is not loaded yet.
      SU.debug("markdown", "Found an embedder for", name)
      return name, handler
    end
  end
  SU.debug("markdown", "No embedder found")
  return nil
end

local metrics = require("fontmetrics")
local bsratiocache = {}

--- Compute the baseline ratio for the current font.
--- This is a ratio of the descender to the theoretical height of the font.
--- @return   number   Descender ratio
local computeBaselineRatio = function ()
  local fontoptions = SILE.font.loadDefaults({})
  local bsratio = bsratiocache[SILE.font._key(fontoptions)]
  if not bsratio then
    local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
    local m = metrics.get_typographic_extents(face)
    bsratio = m.descender / (m.ascender + m.descender)
    bsratiocache[SILE.font._key(fontoptions)] = bsratio
  end
  return bsratio
end

--- @export
return {
  getFileExtension = getFileExtension,
  nbspFilter = nbspFilter,
  hasClass = hasClass,
  hasRawHandler = hasRawHandler,
  hasEmbedHandler = hasEmbedHandler,
  computeBaselineRatio = computeBaselineRatio,
}
