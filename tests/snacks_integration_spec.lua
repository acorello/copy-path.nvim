local assert = require("luassert")
local snacks_dir = vim.fn.expand("~/.local/share/nvim/lazy/snacks.nvim")
if vim.fn.isdirectory(snacks_dir) == 0 then
  return -- Optional integration suite; install Snacks to run it.
end

-- Real installed picker/explorer instances, finders, windows and current items.
describe("installed Snacks integration", function()
  local picker, tmp
  before_each(function()
    vim.opt.runtimepath:append(snacks_dir)
    if not _G.Snacks then
      require("snacks").setup({ picker = { enabled = true } })
    end
    tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp .. "/sub", "p")
    tmp = (vim.uv or vim.loop).fs_realpath(tmp)
    vim.fn.writefile({ "fixture" }, tmp .. "/file.lua")
  end)
  after_each(function()
    if picker then
      picker:close()
    end
    vim.wait(100)
    vim.fn.delete(tmp, "rf")
  end)
  local function select(source, name)
    picker = require("snacks.picker").pick({ source = source, cwd = tmp })
    assert.is_true(vim.wait(5000, function()
      for i, item in ipairs(picker:items()) do
        if item.file and vim.fn.fnamemodify(item.file, ":t") == name then
          picker.list:view(i)
          picker:focus("list")
          local current = picker:current()
          return vim.bo.filetype == "snacks_picker_list" and current and current.file == item.file
        end
      end
      return false
    end, 10))
  end
  it("resolves the explorer current item using the list of active pickers", function()
    select("explorer", "file.lua")
    assert.equals(tmp .. "/file.lua", require("copy-path.tree").get_path())
    assert.equals(tmp .. "/file.lua", require("copy-path").get("full"))
  end)
  it("resolves other file pickers without treating get() as an item", function()
    select("files", "file.lua")
    assert.equals(tmp .. "/file.lua", require("copy-path.tree").get_path())
  end)
  it("ignores directory selections", function()
    select("explorer", "sub")
    assert.is_nil(require("copy-path.tree").get_path())
    assert.equals("", require("copy-path").get("relative"))
  end)
end)
