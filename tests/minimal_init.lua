vim.cmd("filetype plugin indent off")
vim.opt.runtimepath = { vim.env.VIMRUNTIME, "." }
vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"))
