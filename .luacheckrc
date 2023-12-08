std = "min+sile"
include_files = {
  "**/*.lua",
  "*.rockspec",
  ".busted",
  ".luacheckrc"
}
exclude_files = {
  "lua_modules",
  -- "lua-libraries",
  ".lua",
  ".luarocks",
  ".install"
}
files["**/*_spec.lua"] = {
  std = "+busted"
}
max_line_length = false
ignore = {
  "581" -- operator order warning doesn't account for custom table metamethods
}
-- vim: ft=lua
