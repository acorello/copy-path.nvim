local M = {}

function M.check()
  vim.health.start("copy-path")

  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim >= 0.9")
  else
    vim.health.error("Neovim >= 0.9 required")
  end

  if vim.fn.has("clipboard") == 1 then
    vim.health.ok("clipboard provider found")
  else
    vim.health.warn("no clipboard provider detected", {
      "install xclip (X11), wl-clipboard (Wayland), or pbcopy (macOS)",
    })
  end

  if pcall(require, "which-key") then
    vim.health.ok("which-key.nvim found (optional)")
  else
    vim.health.info("which-key.nvim not found — group labels disabled (optional)")
  end

  if pcall(require, "notify") then
    vim.health.ok("nvim-notify found (optional)")
  else
    vim.health.info("nvim-notify not found — falling back to vim.notify (optional)")
  end
end

return M
