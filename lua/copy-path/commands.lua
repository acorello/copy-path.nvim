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
      vim.api.nvim_create_user_command(cmd, function()
        copy_fn(kind)
      end, { desc = "Copy " .. kind:gsub("_", " ") .. " to clipboard" })
    end
  end
end

return M
