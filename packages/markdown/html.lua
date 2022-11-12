local base = require("packages.base")
local utils = require("packages.markdown.utils")

local package = pl.class(base)
package._name = "markdown.html"

local passthroughs = {
  "sup",
  "sub",
  "em",
  "strong",
  { ["div"] = "hbox" },
  { ["b"] = "strong" },
  { ["i"] = "em" },
}

package.registerHTMLcommands = function(self)
  self:registerCommand("markdown:html:br", function (_, _)
    SU.debug("markdown", "warning: manual linebreak (\\cr) inserted")
    SILE.call("cr")
  end, "HTML <br/> in Markdown")

  for _, p in pairs(passthroughs) do
    local html_name, sile_name
    if type(p) == "table" then
      html_name, sile_name = next(p), p[next(p)]
    else
      html_name, sile_name = p, p
    end

    self:registerCommand("markdown:html:" .. html_name, function(options, content)
      SU.debug("markdown", "info: " .. html_name .. " replaced by \\" .. sile_name)
      return utils.createCommand(sile_name, options, content)
    end)
  end
end

package.documentation = [[\begin{document}
A helper package for Markdown processing, providing HTML support.

It is not intended to be used alone.
\end{document}]]

return package
