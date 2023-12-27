std = "min+sile"
include_files = {
  "**/*.lua",
  "*.rockspec",
  ".busted",
  ".luacheckrc"
}
exclude_files = {
  "lua_modules",
  ".lua",
  ".luarocks",
  ".install"
}
globals = {
  -- acceptable as SILE has the necessary compatibility shims:
  -- pl.utils.unpack provides extra functionality and nil handling
  -- but our modules shouldn't be using that anyway.
  "table.unpack"
}
files["**/*_spec.lua"] = {
  std = "+busted"
}
-- Vendored libraries with our modifications and/or extensions:
-- We want to ensure a minimal level of decent linting on these files
-- in order to avoid the worst mistakes when modifying them.
files["lua-libraries/lunamark"] = {
  globals = {
    -- used in compatibility shims and feature detection
    "loadstring",
    "setfenv",
    "unpack",
    "utf8",
  },
}
files["lua-libraries/djot.lua"] = {
  globals = {
    -- used in compatibility shims and feature detection
    "unpack",
  },
  ignore = {
    -- -- matter of taste and not harmful
    "211", -- unused function / unused variable
    "212", -- unused argument
  }
}
files["lua-libraries/djot"] = {
  globals = {
    -- used in compatibility shims and feature detection
    "loadstring",
    "unpack",
    "utf8",
  },
  ignore = {
    -- usually bad but used in compatiblity shims...
    "121", -- setting a read-only global variable
    -- usually questionable but weird use in constructors...
    "312", -- value of argument self is overwritten before use
    -- matter of taste and not harmful
    "211", -- unused function / unused variable
    "212", -- unused argument
    "213", -- unused loop variable
  }
}
max_line_length = false
ignore = {
  "581" -- operator order warning doesn't account for custom table metamethods
}
-- vim: ft=lua
