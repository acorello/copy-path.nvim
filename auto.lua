-- Auto-demo: show ALL copy-path features
-- Groups commands + keymaps together, shows which-key popups

local function type_keys(keys, delay, callback)
  local i = 0
  local function next_key()
    i = i + 1
    if i > #keys then
      if callback then vim.defer_fn(callback, 200) end
      return
    end
    local key = vim.api.nvim_replace_termcodes(keys:sub(i, i), true, false, true)
    vim.api.nvim_feedkeys(key, "t", false)
    vim.cmd("redraw")
    vim.defer_fn(next_key, delay or 60)
  end
  next_key()
end

local function run_steps(steps, i)
  i = i or 1
  if i > #steps then return end
  local step = steps[i]
  vim.defer_fn(function()
    step.fn(function()
      run_steps(steps, i + 1)
    end)
  end, step.wait or 0)
end

-- Type :command, pause 1s to read, then Enter
local function cmd(str)
  return function(cb)
    type_keys(":" .. str, 60, function()
      vim.defer_fn(function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "t", false)
        vim.cmd("redraw")
        if cb then vim.defer_fn(cb, 200) end
      end, 1000)
    end)
  end
end

-- Press <leader>, wait for which-key, press f, wait for submenu, press key
local function leader_f(key)
  return function(cb)
    -- Press <Space> (leader)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Space>", true, false, true), "t", false)
    vim.cmd("redraw")
    -- Wait for which-key top-level popup
    vim.defer_fn(function()
      -- Press f
      vim.api.nvim_feedkeys("f", "t", false)
      vim.cmd("redraw")
      -- Wait for which-key submenu (copy path group)
      vim.defer_fn(function()
        -- Press the final key
        vim.api.nvim_feedkeys(key, "t", false)
        vim.cmd("redraw")
        if cb then vim.defer_fn(cb, 200) end
      end, 1500)
    end, 1500)
  end
end

local function press(str)
  return function(cb)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(str, true, false, true), "t", false)
    vim.cmd("redraw")
    if cb then vim.defer_fn(cb, 200) end
  end
end

local function quit()
  return function()
    vim.cmd("qa!")
  end
end

local steps = {
  -- ── Neo-tree: copy from file explorer ──
  { wait = 1500, fn = cmd("Neotree") },
  { wait = 1500, fn = press("j") },
  { wait = 400,  fn = press("j") },
  { wait = 400,  fn = press("j") },
  { wait = 1000, fn = cmd("CopyPath") },
  { wait = 2500, fn = cmd("CopyPathFull") },
  { wait = 2500, fn = cmd("CopyPathName") },
  { wait = 2500, fn = cmd("Neotree close") },

  -- ── Relative path: command then keymap ──
  { wait = 1500, fn = cmd("CopyPath") },
  { wait = 2500, fn = leader_f("y") },       -- <leader>fy

  -- ── Full path: command then keymap ──
  { wait = 2500, fn = cmd("CopyPathFull") },
  { wait = 2500, fn = leader_f("Y") },       -- <leader>fY

  -- ── Filename: command then keymap ──
  { wait = 2500, fn = cmd("CopyPathName") },
  { wait = 2500, fn = leader_f("N") },       -- <leader>fN

  -- ── Line ref: command then keymap ──
  { wait = 2500, fn = cmd("11") },
  { wait = 1000, fn = cmd("CopyPathLine") },
  { wait = 2500, fn = leader_f("l") },       -- <leader>fl

  -- ── Remaining commands (no default keymaps) ──
  { wait = 2500, fn = cmd("CopyPathLineFull") },
  { wait = 2500, fn = cmd("CopyPathStem") },
  { wait = 2500, fn = cmd("CopyPathExt") },
  { wait = 2500, fn = cmd("CopyPathDir") },
  { wait = 2500, fn = cmd("CopyPathDirRel") },

  -- ── Switch buffer to show it works across buffers ──
  { wait = 2500, fn = cmd("bn") },
  { wait = 1500, fn = leader_f("y") },       -- <leader>fy on second file

  -- exit (fast)
  { wait = 2000, fn = quit() },
}

run_steps(steps)
