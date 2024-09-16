return {
  {
    'mbbill/undotree',

    init = function()
      -- Set Undotree global settings
      vim.g.undotree_WindowLayout = 3
      vim.g.undotree_SplitWidth = 40
      vim.g.undotree_DiffpaneHeight = 20
    end,
  },
}
