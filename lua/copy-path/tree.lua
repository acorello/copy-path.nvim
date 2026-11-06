local M = {}

local tree_filetypes = {
  ["neo-tree"] = true,
  ["NvimTree"] = true,
  ["snacks_picker_list"] = true,
}

function M.is_tree()
  return tree_filetypes[vim.bo.filetype] or false
end

function M.get_path()
  local ft = vim.bo.filetype

  if ft == "neo-tree" then
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if ok then
      local state = manager.get_state("filesystem")
      local node = state and state.tree and state.tree:get_node()
      if node and node.type == "file" then
        return node:get_id()
      end
    end
    return nil
  end

  if ft == "NvimTree" then
    local ok, api = pcall(require, "nvim-tree.api")
    if ok then
      local node = api.tree.get_node_under_cursor()
      if node and not node.nodes then
        return node.absolute_path
      end
    end
    return nil
  end

  if ft == "snacks_picker_list" then
    local ok, picker = pcall(require, "snacks.picker")
    if ok then
      for _, instance in ipairs(picker.get()) do
        if instance:is_focused() then
          local item = instance:current()
          if item and item.file then
            local path = item.file
            if not path:match("^/") then
              path = (item.cwd or instance:cwd()) .. "/" .. path
            end
            if vim.fn.isdirectory(path) == 0 then
              return vim.fn.fnamemodify(path, ":p")
            end
          end
        end
      end
    end
    return nil
  end

  return nil
end

return M
