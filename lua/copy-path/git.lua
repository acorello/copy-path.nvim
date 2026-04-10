local M = {}

local _cache = {}

local function git_cmd(args)
  local result = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 or #result == 0 then
    return nil
  end
  return vim.trim(result[1])
end

function M.root()
  if _cache.root then
    return _cache.root
  end
  _cache.root = git_cmd({ "git", "rev-parse", "--show-toplevel" })
  return _cache.root
end

function M.ref()
  return git_cmd({ "git", "rev-parse", "--abbrev-ref", "HEAD" })
    or git_cmd({ "git", "rev-parse", "HEAD" })
end

function M.remote_url()
  if _cache.remote_url then
    return _cache.remote_url
  end
  local raw = git_cmd({ "git", "remote", "get-url", "origin" })
  if not raw then
    return nil
  end

  local url = raw
  url = url:gsub("^git@([^:]+):", "https://%1/")
  url = url:gsub("%.git$", "")
  url = url:gsub("/$", "")

  _cache.remote_url = url
  return url
end

function M.permalink(abs_path)
  local root = M.root()
  local remote = M.remote_url()
  local ref = M.ref()
  if not root or not remote or not ref then
    return ""
  end

  local rel = abs_path:sub(#root + 2)
  return remote .. "/blob/" .. ref .. "/" .. rel
end

function M.clear_cache()
  _cache = {}
end

return M
