return {
  'dstein64/nvim-scrollview',
  config = function()
    require('scrollview').setup {
      excluded_filetypes = { 'neo-tree' },
      current_only = true,
      signs_on_startup = { 'cursor', 'changelist', 'diagnostic', 'quickfix', 'marks', 'conflicts', 'latestchange' },
      diagnostics_severities = { vim.diagnostic.severity.WARN },
    }
  end,
}
