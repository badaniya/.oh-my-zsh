return {
  'dstein64/nvim-scrollview',
  config = function()
    require('scrollview').setup {
      excluded_filetypes = { 'neo-tree' },
      current_only = true,
      signs_on_startup = { 'all' },
      diagnostics_severities = { vim.diagnostic.severity.ERROR },
    }
  end,
}
