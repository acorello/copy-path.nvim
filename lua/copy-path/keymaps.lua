local M = {}

-- Group registration is opt-in: the default file prefix belongs to LazyVim.
function M.group(keymaps, label)
  if not label then
    return
  end
  local prefix
  for _, lhs in pairs(keymaps) do
    if lhs then
      local parent = lhs:sub(1, -2)
      if prefix and prefix ~= parent then
        return
      end
      prefix = parent
    end
  end
  local ok, wk = pcall(require, "which-key")
  if prefix and prefix ~= "" and ok and type(wk.add) == "function" then
    wk.add({ { prefix, group = label } })
  end
end

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

return M
