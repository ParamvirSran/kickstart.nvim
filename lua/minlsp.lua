-- Minimal CiderLSP config (google3/devtools/cider/ciderlsp/neovim/minlsp.lua).
--
-- The first part of this configuration is not specific to CiderLSP. It just
-- sets up some useful defaults (see the comments).
--
-- Requires Neovim v0.11+

-- Disable backups. Neovim backups by default, deleting the original file and
-- copying the backup over it when saving (:help backupcopy). This messes with
-- iblaze and CiderLSP diagnostics. Another way to address this is setting
-- backupdir to a folder outside CitC, combined with `vim.o.backupcopy = "yes"`.
vim.o.backup = false
vim.o.writebackup = false
vim.o.updatetime = 400 -- Don't wait 4s to trigger CursorHold (highlighting).

-- Improve UI for regular and LSP-based autocompletion, :help completeopt.
vim.opt.completeopt = { "menuone", "noinsert", "noselect", "fuzzy" }
vim.keymap.set("i", "<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { expr = true, desc = "Select next completion item" })
vim.keymap.set("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { expr = true, desc = "Select previous completion item" })

-- Tweak diagnostics (:help vim.diagnostic.config)
vim.diagnostic.config({
  severity_sort = true,     -- Sort diagnostics by severity.
  virtual_text = true,      -- Apply virtual text to line endings.
})

-- Enable optional functionality on LSP attach. See :help lsp-config for
-- defaults.
--
-- NOTE: We don't undo these settings on LspDetach, as that requires tracking
-- and such events are rare.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("minlsp", { clear = true }),
  callback = function(args)
    -- Enable opt-in features, if the LSP server supports them.
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    local lsp_buffer_augroup = vim.api.nvim_create_augroup(string.format("minlsp-client-%d", args.data.client_id), { clear = false })
    local function aucmd(event, callback)
      vim.api.nvim_create_autocmd(event, { group = lsp_buffer_augroup, buffer = args.buf, callback = callback })
    end

    -- Clean up autocommands for this client+buffer.
    aucmd("LspDetach", function(detach)
      vim.api.nvim_clear_autocmds({ group = lsp_buffer_augroup, buffer = detach.buf })
    end)

    -- LSP-based autocompletion.
    if client:supports_method("textDocument/completion", args.buf) then
      vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })

      vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, { buffer = args.buf, desc = "LSP: Manually trigger LSP-based completion" })
      vim.keymap.set("i", "<cr>", function() return (vim.fn.pumvisible() ~= 0) and '<C-y>' or '<cr>' end, { buffer = args.buf, expr = true, desc = "LSP: Accept completion" })
    end

    -- Format on save. Does not fix imports in CiderLSP (see b/207538953).
    if not client:supports_method("textDocument/willSaveWaitUntil", args.buf) and
      client:supports_method("textDocument/formatting", args.buf) then
      aucmd("BufWritePre", function() vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 }) end)
    end

    -- Highlight symbol under cursor in other parts of the document.
    if client:supports_method("textDocument/documentHighlight", args.buf) then
      -- Fix colorschemes which do not support LSP highlight groups.
      if not vim.fn.hlexists("LspReferenceRead") then
        vim.api.nvim_set_hl(0, "LspReferenceRead", { link = "Visual" })
        vim.api.nvim_set_hl(0, "LspReferenceText", { link = "Visual" })
        vim.api.nvim_set_hl(0, "LspReferenceWrite", { link = "Visual" })
      end

      aucmd("CursorHold", function() vim.lsp.buf.document_highlight() end)
      aucmd("CursorMoved", function() vim.lsp.buf.clear_references() end)
    end
  end,
})

--[[ CiderLSP specific ]]--

-- Support a self-contained mode (`nvim -u .../minlsp.lua`) by loading
-- ciderlsp.lua from the folder this script is in on demand. Users who have
-- copied ciderlsp to ~/.config/nvim/lsp/ciderlsp.lua can safely remove this.
if vim.lsp.config["ciderlsp"] == nil then
  vim.lsp.config["ciderlsp"] = assert(loadfile(vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)), "ciderlsp.lua")), "could not load ciderlsp.lua, copy it to ~/.config/nvim/lsp/ciderlsp.lua")()
end

-- Enable CiderLSP. You can also enable other LSPs that you've registered using
-- |vim.lsp.config| or in ~/.config/nvim/lsp/*.lua.
vim.lsp.enable("ciderlsp")
