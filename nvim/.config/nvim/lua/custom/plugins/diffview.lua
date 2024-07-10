return {
  'sindrets/diffview.nvim',
  config = function()
    require('diffview').setup {
      vim.opt.fillchars:append { diff = ' ' },
    }

    -- upstream_branch_name - uses a git command to return the upstream branches name
    local function upstream_branch_name()
      local branch = vim.fn.system 'git rev-parse --abbrev-ref --symbolic-full-name @{upstream}'
      if branch ~= '' then
        return branch
      else
        return ''
      end
    end

    -- Map key bindings
    vim.keymap.set('n', '<leader>do', function()
      vim.cmd('DiffviewOpen ' .. upstream_branch_name())
    end, { noremap = true, silent = true, desc = '[D]iffview [O]pen' })
    vim.keymap.set('n', '<leader>dc', ':DiffviewClose<CR>', { desc = '[D]iffview [C]lose' })
  end,
}
