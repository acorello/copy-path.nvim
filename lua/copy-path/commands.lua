local M = {}

local suffixes = {
  relative = "",
  full = "Full",
  filename = "Name",
  stem = "Stem",
  extension = "Ext",
  dir_full = "Dir",
  dir_rel = "DirRel",
  line = "Line",
  line_full = "LineFull",
  github = "GitHub",
  github_line = "GitHubLine",
}

function M.register(prefix, copy_fn)
  if not prefix then
    return
  end
  for kind, suffix in pairs(suffixes) do
    local cmd = prefix .. suffix
    if vim.fn.exists(":" .. cmd) == 2 then
      vim.notify("copy-path: command :" .. cmd .. " already exists, skipping", vim.log.levels.WARN)
    else
      local line_aware = kind == "line" or kind == "line_full" or kind == "github_line"
      vim.api.nvim_create_user_command(cmd, function(opts)
        copy_fn(kind, opts.range > 0 and { opts.line1, opts.line2 } or nil)
      end, { range = line_aware, desc = "Copy " .. kind:gsub("_", " ") .. " to clipboard" })
    end
  end
end

return M
