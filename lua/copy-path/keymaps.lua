local M = {}

function M.register(keymaps, copy_fn, resolvers, line_kinds)
  for kind, lhs in pairs(keymaps) do
    if lhs and lhs ~= false then
      local r = resolvers[kind]
      if not r then
        vim.notify("copy-path: unknown kind '" .. kind .. "'", vim.log.levels.WARN)
      else
        vim.keymap.set("n", lhs, function()
          copy_fn(kind)
        end, { desc = "Copy " .. r.label })
        if line_kinds[kind] then
          vim.keymap.set("v", lhs, function()
            copy_fn(kind)
          end, { desc = "Copy " .. r.label .. " (range)" })
        end
      end
    end
  end
end

function M.prefixes(keymaps)
  local seen = {}
  for _, lhs in pairs(keymaps) do
    if lhs and lhs ~= false then
      local prefix = lhs:match("^(.+).$")
      if prefix then
        seen[prefix] = true
      end
    end
  end
  return vim.tbl_keys(seen)
end

function M.register_whichkey(group, keymaps)
  if not group then
    return
  end
  local ok = pcall(require, "which-key")
  if not ok then
    return
  end
  -- Don't override the shared <leader>f group label (LazyVim uses "file/find").
  -- Individual keymap descriptions are already set via `desc` in register().
end

return M
