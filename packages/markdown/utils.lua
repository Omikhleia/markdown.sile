--- A few utilities for the markdown / pandocast inputters
--
-- - SILE AST utilities (used for mapping Pandoc/Lunamark AST structures to
--   SILE internal AST).
-- - Other small convenience functions.
--
-- @copyright MIT (c) 2022-2023 Omikhleia
-- @module packages.markdown.utils
--

--- SILE AST utilities
-- @section ast

--- Create a command from a simple content tree.
-- So that's basically the same logic as the "inputfilter" package's
-- createComment() (with col, lno, pos set to 0, as we don't get them
-- from Lunamark or Pandoc.
--
-- @tparam  string command name of the command
-- @tparam  table  options command options
-- @tparam  table  content content tree
-- @treturn table  SILE AST command
local function createCommand (command, options, content)
  local result = { content }
  result.col = 0
  result.lno = 0
  result.pos = 0
  result.options = options or {}
  result.command = command
  result.id = "command"
  return result
end

--- Create a command from a structured content tree.
-- The content is normally a table of an already prepared content list.
--
-- @tparam  string command name of the command
-- @tparam  table  options command options
-- @tparam  table  contents content tree list
-- @treturn table  SILE AST command
local function createStructuredCommand (command, options, contents)
  -- contents = normally a table of an already prepared content list.
  local result = type(contents) == "table" and contents or { contents }
  result.col = 0
  result.lno = 0
  result.pos = 0
  result.options = options or {}
  result.command = command
  result.id = "command"
  return result
end

--- Extract the content tree of a command, assuming we already took care of it.
-- This is SU.subContent() done right, without the id=stuff and other weirdness...
--
-- @tparam table  contents content tree list
local function subTreeContent (content)
  local out = {}
  for _, val in ipairs(content) do
    out[#out+1] = val
  end
  return out
end

--- Remove a command from the AST and return it for separate processing.
--
-- @tparam  table  contents content tree list
-- @tparam  string command name of the command
local function extractFromTree (tree, command)
  for i = 1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return table.remove(tree, i)
    end
  end
end

--- Some other utility functions.
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

--- @export
return {
  getFileExtension = getFileExtension,
  createCommand = createCommand,
  createStructuredCommand = createStructuredCommand,
  subTreeContent = subTreeContent,
  extractFromTree = extractFromTree,
  nbspFilter = nbspFilter,
}
