local M = {}

M.defaults = {
  notify = true,
  which_key_group = "copy path",
  command_prefix = "CopyPath",
  keymaps = {
    relative = "<leader>fy",
    full = "<leader>fY",
    filename = "<leader>fN",
    line = "<leader>fl",
    github_line = "<leader>fG",
    line_full = false,
    stem = false,
    extension = false,
    dir_full = false,
    dir_rel = false,
    github = false,
  },
  picker_keymap = "<leader>fP",
  picker = "auto",
}

function M.resolve(opts)
  return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.validate(cfg)
  local errors = {}
  if type(cfg.notify) ~= "boolean" then
    table.insert(errors, "notify must be boolean")
  end
  if cfg.which_key_group ~= false and type(cfg.which_key_group) ~= "string" then
    table.insert(errors, "which_key_group must be string or false")
  end
  if cfg.command_prefix ~= false and type(cfg.command_prefix) ~= "string" then
    table.insert(errors, "command_prefix must be string or false")
  end
  if type(cfg.keymaps) ~= "table" then
    table.insert(errors, "keymaps must be a table")
  end
  if cfg.picker_keymap ~= false and type(cfg.picker_keymap) ~= "string" then
    table.insert(errors, "picker_keymap must be string or false")
  end
  local valid_pickers = { auto = true, snacks = true, telescope = true, fzf_lua = true }
  if cfg.picker ~= false and not valid_pickers[cfg.picker] then
    table.insert(errors, "picker must be 'auto', 'snacks', 'telescope', 'fzf_lua', or false")
  end
  return errors
end

return M
