local M = {}

local function git_cmd(path, args)
  local cmd = { "git", "-C", path and vim.fn.fnamemodify(path, ":p:h") or vim.fn.getcwd() }
  vim.list_extend(cmd, args)
  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error == 0 and #result > 0 then
    return result[1]
  end
end

function M.root(path)
  return git_cmd(path, { "rev-parse", "--show-toplevel" })
end

function M.ref(path)
  return git_cmd(path, { "rev-parse", "--verify", "HEAD" })
end

function M.remote_url(path)
  local raw = git_cmd(path, { "remote", "get-url", "origin" })
  if not raw then
    return nil
  end
  local url = raw:gsub("^git@([^:]+):", "https://%1/")
  url = url:gsub("^ssh://[^@/]+@([^/]+)/", "https://%1/")
  -- Remove all userinfo before the authority is ever returned to callers.
  url = url:gsub("^(https?://)[^/]*@", "%1")
  if not url:match("^https?://") then
    return nil
  end
  return (url:gsub("/$", ""):gsub("%.git$", ""))
end

function M.permalink(abs_path)
  local path = require("copy-path.path")
  abs_path = path.absolute(abs_path)
  local root = M.root(abs_path)
  local rel = root and path.within(abs_path, root)
  if not rel then
    return ""
  end
  local remote, ref = M.remote_url(abs_path), M.ref(abs_path)
  if not remote or not ref then
    return ""
  end
  local escaped = rel:gsub("[^%w%-%._~/]", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
  return remote .. "/blob/" .. ref .. "/" .. escaped
end

-- Compatibility with earlier releases; metadata is no longer cached.
function M.clear_cache() end

return M
