local assert = require("luassert")
local cp = require("copy-path")
local git = require("copy-path.git")
local path = require("copy-path.path")

describe("behaviour regressions", function()
  local tmp, cwd, setreg, notify, registers, notices
  local function run(dir, ...)
    local cmd = { "git", "-C", dir }
    vim.list_extend(cmd, { ... })
    local output = vim.fn.systemlist(cmd)
    assert.equals(0, vim.v.shell_error, table.concat(output, "\n"))
    return output[1]
  end
  local function repo(name, remote)
    local dir = tmp .. "/" .. name
    vim.fn.mkdir(dir .. "/src", "p")
    vim.fn.writefile({ "one", "two", "three", "four" }, dir .. "/src/file #$;.lua")
    run(dir, "init", "-q")
    run(dir, "add", ".")
    run(dir, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture")
    run(dir, "remote", "add", "origin", remote or "https://example.invalid/org/repo.git")
    return dir, dir .. "/src/file #$;.lua"
  end
  local function open(file)
    vim.cmd.enew()
    vim.cmd.edit(vim.fn.fnameescape(file))
  end
  before_each(function()
    cwd = vim.fn.getcwd()
    tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")
    tmp = (vim.uv or vim.loop).fs_realpath(tmp)
    setreg, notify = vim.fn.setreg, vim.notify
    registers, notices = {}, {}
    vim.fn.setreg = function(reg, value)
      registers[reg] = value
    end
    vim.notify = function(message)
      table.insert(notices, message)
    end
    vim.g.copy_path_setup_done = nil
    cp.setup({ notify = true, picker_keymap = false })
  end)
  after_each(function()
    vim.cmd("silent! normal! \27")
    vim.cmd.enew()
    vim.cmd.cd(vim.fn.fnameescape(cwd))
    vim.fn.setreg, vim.notify = setreg, notify
    vim.fn.delete(tmp, "rf")
  end)

  it("resolves all four file formats from a nested cwd", function()
    local dir, file = repo("project")
    open(file)
    vim.cmd.cd(vim.fn.fnameescape(dir .. "/src"))
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    assert.equals("src/file #$;.lua", cp.get("relative"))
    assert.equals(file, cp.get("full"))
    assert.equals("src/file #$;.lua:2", cp.get("line"))
    assert.equals(file .. ":2", cp.get("line_full"))
  end)

  it("uses markers, then contained cwd, then absolute outside projects", function()
    vim.fn.mkdir(tmp .. "/plain/src", "p")
    vim.fn.writefile({}, tmp .. "/plain/go.mod")
    open(tmp .. "/plain/src/a.go")
    assert.equals("src/a.go", cp.get("relative"))
    vim.fn.delete(tmp .. "/plain/go.mod")
    vim.cmd.cd(vim.fn.fnameescape(tmp))
    assert.equals("plain/src/a.go", cp.get("relative"))
    vim.cmd.cd(vim.fn.fnameescape(cwd))
    assert.equals(tmp .. "/plain/src/a.go", cp.get("relative"))
    assert.is_nil(path.within(tmp .. "/project-other/a", tmp .. "/project"))
  end)

  it("does not copy unnamed buffers or generate URLs without repository metadata", function()
    vim.cmd.enew()
    assert.equals("", cp.get("relative"))
    assert.equals("", cp.get("full"))
    cp.copy("line")
    assert.is_nil(registers["+"])
    local dir = tmp .. "/empty"
    vim.fn.mkdir(dir, "p")
    run(dir, "init", "-q")
    local file = dir .. "/new.txt"
    run(dir, "remote", "add", "origin", "https://example.invalid/repo.git")
    assert.equals("", git.permalink(file))
    local committed, selected = repo("unsupported", "/local/repository.git")
    assert.equals("", git.permalink(selected))
    run(committed, "remote", "remove", "origin")
    assert.equals("", git.permalink(selected))
  end)

  it("supports an editor root callback and rejects unrelated roots", function()
    local dir, file = repo("project")
    open(file)
    vim.g.copy_path_setup_done = nil
    cp.setup({
      root = function(selected, buf)
        assert.equals(file, selected)
        assert.equals(vim.api.nvim_get_current_buf(), buf)
        return dir .. "/src"
      end,
    })
    assert.equals("file #$;.lua", cp.get("relative"))
    vim.g.copy_path_setup_done = nil
    cp.setup({
      root = function()
        return tmp .. "/unrelated"
      end,
    })
    assert.equals(file, cp.get("relative"))
  end)

  it("isolates repositories and refreshes remote and commit metadata", function()
    local a, file_a = repo("repo A;$")
    local b, file_b = repo("repo B", "git@example.invalid:other/repo.git")
    vim.cmd.cd(vim.fn.fnameescape(a))
    local sha_b = run(b, "rev-parse", "HEAD")
    assert.equals(
      "https://example.invalid/other/repo/blob/" .. sha_b .. "/src/file%20%23%24%3B.lua",
      git.permalink(file_b)
    )
    assert.equals(
      "https://example.invalid/org/repo/blob/" .. run(a, "rev-parse", "HEAD") .. "/src/file%20%23%24%3B.lua",
      git.permalink(file_a)
    )
    run(b, "remote", "set-url", "origin", "https://example.invalid/new/repo.git")
    run(b, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-qm", "next")
    assert.equals(
      "https://example.invalid/new/repo/blob/" .. run(b, "rev-parse", "HEAD") .. "/src/file%20%23%24%3B.lua",
      git.permalink(file_b)
    )
    assert.equals("", git.permalink(tmp .. "/outside.lua"))
  end)

  it("strips HTTP credentials before copying or notifying and uses detached SHA", function()
    local dir, file = repo("credentials", "https://user:FAKE_TEST_TOKEN@example.invalid/org/repo.git")
    run(dir, "checkout", "--detach", "-q")
    open(file)
    local expected = "https://example.invalid/org/repo/blob/"
      .. run(dir, "rev-parse", "HEAD")
      .. "/src/file%20%23%24%3B.lua"
    cp.copy("github")
    assert.equals(expected, registers["+"])
    assert.is_nil(registers['"'])
    assert.equals("GitHub URL: " .. expected, notices[#notices])
    run(dir, "remote", "set-url", "origin", "http://user:FAKE_TEST_TOKEN@example.invalid/org/repo.git")
    assert.equals("http://example.invalid/org/repo", git.remote_url(file))
  end)

  it("accepts explicit single lines, ranges and visual Ex marks", function()
    local _, file = repo("ranges")
    open(file)
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    vim.cmd("CopyPathLine")
    assert.equals("src/file #$;.lua:3", registers["+"])
    vim.cmd("2CopyPathLine")
    assert.equals("src/file #$;.lua:2", registers["+"])
    vim.cmd("1,3CopyPathLineFull")
    assert.equals(file .. ":1-3", registers["+"])
    vim.fn.setpos("'<", { 0, 2, 1, 0 })
    vim.fn.setpos("'>", { 0, 4, 1, 0 })
    vim.cmd("'<,'>CopyPathLine")
    assert.equals("src/file #$;.lua:2-4", registers["+"])
    vim.cmd("2,2CopyPathGitHubLine")
    assert.matches("#L2$", registers["+"])
    cp.copy("line", { 4, 2 })
    assert.equals("src/file #$;.lua:2-4", registers["+"])
  end)

  it("handles reverse and single-line live visual selections", function()
    local _, file = repo("visual")
    open(file)
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    vim.cmd("normal! Vkk")
    assert.equals("src/file #$;.lua:2-4", cp.get("line"))
    assert.matches("#L2%-L4$", cp.get("github_line"))
    vim.cmd("normal! \27")
    vim.cmd("normal! v")
    assert.equals("src/file #$;.lua:2", cp.get("line"))
  end)

  it("copies the captured picker value even if the buffer changes", function()
    local _, file = repo("picker")
    open(file)
    local old = package.loaded["snacks.picker"]
    package.loaded["snacks.picker"] = {
      pick = function(opts)
        local entry
        for _, item in ipairs(opts.items) do
          if item.item.kind == "relative" then
            entry = item
          end
        end
        vim.cmd.enew()
        opts.confirm({ close = function() end }, entry)
      end,
    }
    local ok, err = pcall(cp.pick)
    package.loaded["snacks.picker"] = old
    assert.is_true(ok, err)
    assert.equals("src/file #$;.lua", registers["+"])
  end)

  it("registers an opt-in which-key group, not a default file-group override", function()
    local old = package.loaded["which-key"]
    local groups = {}
    package.loaded["which-key"] = {
      add = function(spec)
        groups = spec
      end,
    }
    require("copy-path.keymaps").group({ relative = "<leader>yr", full = "<leader>ya" }, "copy path")
    package.loaded["which-key"] = old
    assert.same({ { "<leader>y", group = "copy path" } }, groups)
    assert.is_false(require("copy-path.config").defaults.which_key_group)
  end)
end)
