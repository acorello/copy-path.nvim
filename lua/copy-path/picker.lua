local M = {}

local function build_items(resolvers)
  local items = {}
  for kind, r in pairs(resolvers) do
    local value = r.fn()
    if value and value ~= "" then
      table.insert(items, {
        kind = kind,
        value = value,
        label = r.label,
        display = r.label .. ": " .. value,
      })
    end
  end
  table.sort(items, function(a, b)
    return a.label < b.label
  end)
  return items
end

function M.open(resolvers, on_select, backend)
  local items = build_items(resolvers)
  if #items == 0 then
    return
  end

  if backend == false then
    return
  end

  local function try_snacks()
    local ok, snacks = pcall(require, "snacks.picker")
    if not ok then
      return false
    end
    snacks.pick({
      source = "copy-path",
      items = vim.tbl_map(function(item)
        return { text = item.display, item = item }
      end, items),
      format = function(entry)
        local item = entry.item
        return {
          { item.label .. ": ", "Special" },
          { item.value },
        }
      end,
      confirm = function(picker_inst, entry)
        picker_inst:close()
        on_select(entry.item.kind)
      end,
    })
    return true
  end

  local function try_telescope()
    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
      return false
    end
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
      .new({}, {
        prompt_title = "Copy Path",
        finder = finders.new_table({
          results = items,
          entry_maker = function(item)
            return { value = item, display = item.display, ordinal = item.display }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            on_select(entry.value.kind)
          end)
          return true
        end,
      })
      :find()
    return true
  end

  local function try_fzf_lua()
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
      return false
    end
    local displays = vim.tbl_map(function(item)
      return item.display
    end, items)
    fzf.fzf_exec(displays, {
      prompt = "Copy Path> ",
      actions = {
        ["default"] = function(selected)
          for _, item in ipairs(items) do
            if item.display == selected[1] then
              on_select(item.kind)
              break
            end
          end
        end,
      },
    })
    return true
  end

  local function try_vim_ui()
    local displays = vim.tbl_map(function(item)
      return item.display
    end, items)
    vim.ui.select(displays, { prompt = "Copy Path:" }, function(choice)
      if not choice then
        return
      end
      for _, item in ipairs(items) do
        if item.display == choice then
          on_select(item.kind)
          break
        end
      end
    end)
    return true
  end

  local backends = {
    snacks = try_snacks,
    telescope = try_telescope,
    fzf_lua = try_fzf_lua,
  }

  if backend and backend ~= "auto" then
    local fn = backends[backend]
    if fn and fn() then
      return
    end
    vim.notify("copy-path: picker '" .. backend .. "' not available, falling back", vim.log.levels.WARN)
  end

  if try_snacks() then
    return
  end
  if try_telescope() then
    return
  end
  if try_fzf_lua() then
    return
  end
  try_vim_ui()
end

return M
