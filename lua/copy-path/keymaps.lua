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


return M
