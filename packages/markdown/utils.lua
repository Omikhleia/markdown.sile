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

local function hasClass (options, classname)
  -- N.B. we want a true boolean here
  if options.class and string.match(' ' .. options.class .. ' ',' '..classname..' ') then
    return true
  end
  return false
end

--- @export
return {
  getFileExtension = getFileExtension,
  nbspFilter = nbspFilter,
  hasClass = hasClass
}
