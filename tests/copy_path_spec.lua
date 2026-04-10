local assert = require("luassert")
local cp = require("copy-path")

describe("copy-path", function()
  before_each(function()
    vim.g.copy_path_setup_done = nil
  end)

  describe("setup()", function()
    it("does not error with no args", function()
      assert.has_no.errors(function()
        cp.setup()
      end)
    end)
    it("does not error with empty opts", function()
      assert.has_no.errors(function()
        cp.setup({})
      end)
    end)
    it("accepts notify = false", function()
      assert.has_no.errors(function()
        cp.setup({ notify = false })
      end)
    end)
    it("accepts command_prefix = false", function()
      assert.has_no.errors(function()
        cp.setup({ command_prefix = false })
      end)
    end)
    it("accepts keymaps with false values", function()
      assert.has_no.errors(function()
        cp.setup({ keymaps = { relative = false, full = false } })
      end)
    end)
    it("accepts picker = false", function()
      assert.has_no.errors(function()
        cp.setup({ picker = false, picker_keymap = false })
      end)
    end)
    it("is a no-op on second call", function()
      cp.setup({})
      assert.is_true(vim.g.copy_path_setup_done)
      assert.has_no.errors(function()
        cp.setup({ notify = false })
      end)
    end)
  end)

  describe("get()", function()
    it("returns a string for 'relative'", function()
      assert.is_string(cp.get("relative"))
    end)
    it("returns a string for 'full'", function()
      assert.is_string(cp.get("full"))
    end)
    it("returns a string for 'line'", function()
      local val = cp.get("line")
      assert.is_string(val)
    end)
    it("returns a string for 'github'", function()
      -- May be empty outside a git repo, but should not error
      assert.is_string(cp.get("github"))
    end)
    it("returns a string for 'github_line'", function()
      assert.is_string(cp.get("github_line"))
    end)
    it("returns empty string for no-file buffer", function()
      local val = cp.get("relative")
      assert.is_string(val)
    end)
    it("errors on unknown kind", function()
      assert.has_errors(function()
        cp.get("nonexistent_kind")
      end)
    end)
  end)

  describe("copy()", function()
    before_each(function()
      cp.setup({ notify = false })
    end)
    it("errors on unknown kind", function()
      assert.has_errors(function()
        cp.copy("nonexistent_kind")
      end)
    end)
    it("does not error on valid kind", function()
      assert.has_no.errors(function()
        cp.copy("relative")
      end)
    end)
  end)

  describe("resolvers()", function()
    it("returns a table", function()
      assert.is_table(cp.resolvers())
    end)
    it("contains all 11 kinds", function()
      local r = cp.resolvers()
      local kinds = {
        "relative",
        "full",
        "filename",
        "stem",
        "extension",
        "dir_full",
        "dir_rel",
        "line",
        "line_full",
        "github",
        "github_line",
      }
      for _, k in ipairs(kinds) do
        assert.is_not_nil(r[k], "missing resolver for kind: " .. k)
      end
    end)
    it("each resolver has fn and label", function()
      for kind, r in pairs(cp.resolvers()) do
        assert.is_function(r.fn, kind .. " missing fn")
        assert.is_string(r.label, kind .. " missing label")
      end
    end)
  end)
end)
