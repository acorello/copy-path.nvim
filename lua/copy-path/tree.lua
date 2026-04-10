local M = {}

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
      local current = picker.get and picker.get()
      if current and current.item and current.item.file then
        return current.item.file
      end
    end
    return nil
  end

  return nil
end

return M
