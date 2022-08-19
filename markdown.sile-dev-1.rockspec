package = "markdown.sile"
version = "dev-1"
source = {
    url = "git+https://github.com/Omikhleia/markdown.sile.git",
}
description = {
  summary = "Native Markdown support for the SILE typesetting system.",
  detailed = [[
    This package set for the SILE typesetting system provides a complete redesign
    of the native Markdown support for SILE, with a great set of Pandoc-like
    extensions and plenty of extra goodies.
  ]],
  homepage = "https://github.com/Omikhleia/markdown.sile",
  license = "MIT",
}
dependencies = {
   "lua >= 5.1",
   "ptable.sile",
   "textsubsuper.sile"
}

build = {
   type = "builtin",
   modules = {
      ["sile.classes.markdown"]           = "classes/markdown.lua",
      ["sile.inputters.markdown"]         = "inputters/markdown.lua",
      ["sile.inputters.pandocast"]        = "inputters/pandocast.lua",
      ["sile.packages.markdown"]          = "packages/markdown/init.lua",
      ["sile.packages.markdown.commands"] = "packages/markdown/commands.lua",
      ["sile.packages.markdown.utils"]    = "packages/markdown/utils.lua",
      ["sile.packages.pandocast"]         = "packages/pandocast/init.lua",
      ["sile.core.ast"]                   = "core/ast.lua",

      ["sile.lunamark"]                 = "lua-libraries/lunamark.lua",
      ["sile.lunamark.entities"]        = "lua-libraries/lunamark/entities.lua",
      ["sile.lunamark.reader"]          = "lua-libraries/lunamark/reader.lua",
      ["sile.lunamark.reader.markdown"] = "lua-libraries/lunamark/reader/markdown.lua",
      ["sile.lunamark.util"]            = "lua-libraries/lunamark/util.lua",
      ["sile.lunamark.writer"]          = "lua-libraries/lunamark/writer.lua",
      ["sile.lunamark.writer.generic"]  = "lua-libraries/lunamark/writer/generic.lua",
      ["sile.lunamark.writer.html"]     = "lua-libraries/lunamark/writer/html.lua",
      ["sile.lunamark.writer.html5"]    = "lua-libraries/lunamark/writer/html5.lua",
   }
}
