local M = {}

function M.absolute(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

function M.within(path, root)
  local uv = vim.uv or vim.loop
  root = (uv.fs_realpath(root) or M.absolute(root)):gsub("/+$", "") .. "/"
  path = uv.fs_realpath(path) or M.absolute(path)
  if path:sub(1, #root) == root then
    return path:sub(#root + 1)
  end
end

function M.relative(path, root_fn)
  path = M.absolute(path)
  local root = root_fn and root_fn(path, vim.api.nvim_get_current_buf())
  if not root then
    root = require("copy-path.git").root(path)
  end
  if not root then
    local marker = vim.fs.find({ ".git", "package.json", "pyproject.toml", "go.mod", "Cargo.toml" }, {
      path = vim.fn.fnamemodify(path, ":h"),
      upward = true,
    })[1]
    root = marker and vim.fn.fnamemodify(marker, ":h")
  end
  return (root and M.within(path, root)) or M.within(path, vim.fn.getcwd()) or path
end

return M
