-- CiderLSP uses --request_options instead of the standard LSP 'settings' field.
-- See go/ciderlsp-settings for available options.
local ciderlsp_settings = {
  "enable_placeholders", -- Enable completion placeholders (go/cider-v-lsp-features#code-completion).
  "enable:inlay_hints_kotlin_show_local_variable_types", -- Inlay hints for kotlin local variable types.
}

---@type vim.lsp.ClientConfig
return {
  cmd = {
    "/google/bin/releases/cider/ciderlsp/ciderlsp",
    "--tooltag=nvim-lsp",
    "--noforward_sync_responses",
    "--request_options=" .. table.concat(ciderlsp_settings, ",")
  },
  -- Languages supported by CiderLSP, see go/ciderlsp.
  filetypes = { "borg", "bzl", "c", "cpp", "cs", "dart", "gcl", "go", "googlesql", "graphql", "java", "kotlin", "markdown", "mlir", "ncl", "objc", "patchpanel", "proto", "python", "qflow", "soy", "swift", "textpb", "typescript" },
  -- Optimistically assume any file under /google is a CiderLSP project. This
  -- avoids the overhead of walking up the tree searching for .citc markers.
  --
  -- TODO(aktau): A note on /google/obj: the C++ integration sometimes uses
  -- this, but most of the time this leads to errors (path not under
  -- /google/src/cloud/*/*. Consider root_dir = "/google/src/cloud".
  root_dir = function(bufnr, cb)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root_dir = "/google"
    if vim.startswith(fname, root_dir) then
      cb(root_dir)
    end
  end,
}
