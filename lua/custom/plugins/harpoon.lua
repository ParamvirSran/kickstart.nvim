-- Harpoon navigation
vim.pack.add {
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
}

local harpoon = require 'harpoon'
harpoon:setup()

vim.keymap.set('n', '<C-a>', function()
  harpoon:list():add()
end, { desc = 'Harpoon: Add file' })

vim.keymap.set('n', '<leader>h', function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = 'Harpoon: Quick menu' })

for _, idx in ipairs { 1, 2, 3, 4, 5 } do
  vim.keymap.set('n', string.format('<leader>%d', idx), function()
    harpoon:list():select(idx)
  end, { desc = string.format('Harpoon: Select file %d', idx) })
end
