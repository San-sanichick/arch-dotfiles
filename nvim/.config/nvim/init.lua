-- Basic settings
vim.loader.enable()
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = "unnamedplus" end)
vim.cmd("language en_US.UTF-8")
vim.o.signcolumn = "yes"

vim.diagnostic.config({
    update_in_insert = false,
    virtual_text = true,
    virtual_lines = { current_line = true },
    float = { border = "rounded" },
})

vim.o.termguicolors = true
vim.o.background = "dark"
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.winborder = "rounded"

vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.wrap = false
vim.o.confirm = true

-- PLUGINS
local pattern = "^(%d+)"
local path_pattern = ".*[%/%\\]"
--- Parses an integer from a string
--- @param num string
--- @return number?
local function parseInt(num)
    return tonumber(string.match(num, pattern))
end
--- comment
--- @param path string
--- @return string
local function getLastPathEntry(path)
    local last = path:gsub(path_pattern, '')
    return last
end

local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
        local stderr = result.stderr or ''
        local stdout = result.stdout or ''
        local output = stderr ~= '' and stderr or stdout
        if output == '' then output = 'No output from build command.' end
        vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
end

vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name = ev.data.spec.name
        local kind = ev.data.kind

        if name == 'fff' and (kind == 'install' or kind == 'update') then
            if not ev.data.active then vim.cmd.packadd('fff') end
            require('fff.download').download_or_build_binary()
        end

        if kind ~= 'install' and kind ~= 'update' then return end

        if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
            run_build(name, { 'make' }, ev.data.path)
            return
        end

        if name == 'LuaSnip' then
            if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
            return
        end

        if name == 'nvim-treesitter' then
            if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
            vim.cmd 'TSUpdate'
            return
        end
    end,
})

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add({ gh "tjdevries/colorbuddy.nvim" })
vim.pack.add({ gh "2nthony/vitesse.nvim" })
vim.cmd.colorscheme("vitesse")


require("vitesse").setup {
    comment_italics = false,
    transparent_background = false,
    transparent_float_background = false, -- aka pum(popup menu) background
--    reverse_visual = false,
--    dim_nc = false,
--    cmp_cmdline_disable_search_highlight_group = false, -- disable search highlight group for cmp item
--    -- if `transparent_float_background` false, make telescope border color same as float background
--    telescope_border_follow_float_background = false,
--    -- diagnostic virtual text background, like error lens
--    diagnostic_virtual_text_background = true,
}

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    
    -- Ensure the active LSP server supports semantic tokens
    if client and client.server_capabilities.semanticTokensProvider then
      -- Fallback link maps if they are empty
      vim.api.nvim_set_hl(0, "@lsp.type.variable", { link = "@variable" })
      vim.api.nvim_set_hl(0, "@lsp.type.function", { link = "@function" })
      vim.api.nvim_set_hl(0, "@lsp.type.keyword", { link = "@keyword" })
    end
  end,
})

vim.pack.add({ gh "akinsho/bufferline.nvim" })
require("bufferline").setup({
    options = {
        highlights = require("vitesse.plugins.bufferline"),
        offsets = {
            {
                filetype = "neo-tree",
                text = "Files",
                highlight = "Directory",
                text_align = "left",
            },
        },
    }
})



vim.pack.add({ gh "Shatur/neovim-session-manager" })

vim.pack.add({
    {
        src = gh "nvim-neo-tree/neo-tree.nvim",
        version = vim.version.range("3")
    },
    gh "nvim-lua/plenary.nvim",
    gh "MunifTanjim/nui.nvim",
    gh "nvim-tree/nvim-web-devicons"
})
local neotree = require("neo-tree")
local function on_move(data)
    Snacks.rename.on_rename_file(data.source, data.destination)
end
neotree.setup({
    filesystem = {
        follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
        },
    },
    window = {
        mappings = {
            ["<C-b>"] = "noop",
        }
    },
    sort_function = function(a, b)
        if a.type == b.type then
            local ap = parseInt(getLastPathEntry(a.path))
            local bp = parseInt(getLastPathEntry(b.path))
            if ap == nil or bp == nil then
                return a.path < b.path
            else
                return ap < bp
            end
        else
            return a.type < b.type
        end
    end,
    event_handlers = {
        {
            event = "file_renamed",
            handler = function(args)
                on_move(args)
                -- fix references to file
                print(args.source, " renamed to ", args.destination)
            end
        },
        {
            event = "file_moved",
            handler = function(args)
                on_move(args)
                -- fix references to file
                print(args.source, " moved to ", args.destination)
            end
        },
    }

})
vim.pack.add({ gh "folke/snacks.nvim" })

require("snacks").setup({
    picker = {
        sources = {
            explorer = {
                enabled = false,
            }
        },
        layouts = {
            telescope = {
                reverse = false, -- true to put the input bar at the top
                layout = {
                    box = "horizontal",
                    backdrop = false,
                    width = 0.9, -- Default width ratio (80% of screen)
                    height = 0.9, -- Default height ratio
                    {
                        box = "vertical",
                        {
                            win = "list",
                            title = " Results ",
                            title_pos = "center",
                            border = true
                        },
                        {
                            win = "input",
                            height = 1,
                            border = true,
                            title = "{title} {live} {flags}",
                            title_pos = "center"
                        },
                    },
                    win = "preview",
                    title = "{preview:Preview}",
                    width = 0.65,
                    border = true,
                    title_pos = "center",
                },
            },
        },
    },
    bigfile = { enabled = false },
    quickfile = { enabled = false },
    words = { enabled = false },
    terminal = { enabled = false },
    toggle = { enabled = false },
    lazygit = { enabled = false },
    -- git = { enabled = false },
    gitbrowse = { enabled = false },
    debug = { enabled = false },
    bufdelete = { enabled = false },
    rename = { enabled = true },
})

vim.pack.add({ gh "folke/trouble.nvim" })


vim.pack.add({ gh "lewis6991/gitsigns.nvim" })
vim.pack.add({ gh "folke/which-key.nvim" })

vim.pack.add({ gh "nvim-mini/mini.nvim" })
require("mini.surround").setup()
require("mini.trailspace").setup()
require("mini.pairs").setup()
require("mini.move").setup({
    mappings = {
        up = "<M-k>",
        down = "<M-j>",

        line_up = "<M-k>",
        line_down = "<M-j>"
    },
    options = {
        reindent_linewise = true,
    }
})

vim.pack.add({ gh "godlygeek/tabular" })

vim.pack.add({ gh "NStefan002/visual-surround.nvim" })
require("visual-surround").setup({ })


vim.pack.add({ gh "nvim-lualine/lualine.nvim" })
require("lualine").setup({
    options = {
       theme = "auto"
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { "diagnostics" },
--      lualine_x = {
--          function ()
--              return require("lsp-progress").progress()
--          end
--      },
        lualine_z = { "location" }
    },
    extensions = { "neo-tree" }
})

vim.pack.add({ gh "HiPhish/rainbow-delimiters.nvim" })
local rainbow_delimiters = require('rainbow-delimiters')
require('rainbow-delimiters.setup').setup({
    strategy = {
        [''] = rainbow_delimiters.strategy['global'],
        vim = rainbow_delimiters.strategy['local'],
    },
    query = {
        [''] = 'rainbow-delimiters',
        lua = 'rainbow-blocks',
    },
    highlight = {
        'RainbowDelimiterRed',
        'RainbowDelimiterYellow',
        'RainbowDelimiterBlue',
        'RainbowDelimiterOrange',
        'RainbowDelimiterGreen',
        'RainbowDelimiterViolet',
        'RainbowDelimiterCyan',
    },
})
vim.pack.add({ gh "lukas-reineke/indent-blankline.nvim" })
local hooks = require("ibl.hooks")

hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "BlanklineContextChar", { fg = "#928374" })
    vim.api.nvim_set_hl(0, "BlankLineChar", { fg = "#665c54" })
end)

require("ibl").setup({
    indent = {
        highlight = { "BlankLineChar" },
        char = '┊'
    },
    scope = {
        highlight = { "BlanklineContextChar" },
        char = '│'
    }
})

vim.pack.add({ gh "folke/todo-comments.nvim" })
require("todo-comments").setup({
    keywords = {
        FIX = {
            icon = " ", -- icon used for the sign, and in search results
            color = "error", -- can be a hex color, or a named color (see below)
            alt = { "FIXME", "BUG", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
    }
})

vim.pack.add({ gh "dmtrKovalenko/fff" })
vim.g.fff = {
    lazy_sync = true,
    debug = { enabled = true, show_scores = true },
}
require("fff").setup({
    prompt = "> ",
    layout = {
        width = 0.9,
        height = 0.8,
        preview_position = "right"
    },
    preview = {
        enabled = true,
    }
})

-- ---@type (string|vim.pack.Spec)[]
-- local telescope_plugins = {
--   gh 'nvim-lua/plenary.nvim',
--   gh 'nvim-telescope/telescope.nvim',
--   gh 'nvim-telescope/telescope-ui-select.nvim',
-- }
-- if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end
--
-- --require("telescope").setup({})
--
-- -- NOTE: You can install multiple plugins at once
-- vim.pack.add(telescope_plugins)
--pcall(require('telescope').load_extension, 'fzf')

-- lsp
vim.pack.add({ gh "j-hui/fidget.nvim" })
require("fidget").setup()

vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

require("mason").setup({})
require("mason-lspconfig").setup({
    automatic_enable = true,
})

local servers = {
    clangd = {
        cmd = { "clangd", "--background-index", "--clang-tidy", "--query-driver=**/em++,**/clang*", "--log=verbose" },
        initialization_options = {
            fallback_flags = { '-std=c++17' },
        },
    },
    tsc = {},
    html = {},
    emmet_language_server = {},
    cssls = {},
    glsl_analyzer = {},
    bashls = {},
}

local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
    -- You can add other tools here that you want Mason to install
})

require("mason-tool-installer").setup({
    ensure_installed = ensure_installed,
})

for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
end


-- Snippets + Autocomplete
vim.pack.add({ { src = gh "L3MON4D3/LuaSnip", version = vim.version.range("2.*") } })
require("luasnip").setup({})
require("snippets")

vim.pack.add({ { src = gh "saghen/blink.cmp", version = vim.version.range("1.*") } })
require("blink.cmp").setup({
    keymap = {
        preset = "super-tab",
    },
    appearance = {
        nerd_font_variant = "mono",
    },
    completion = {
        menu = {
            border = "rounded",
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
        },
        documentation = {
            window = {
                border = "rounded",
            },
        },
    },
    sources = {
        default = { 'lsp', 'path', 'snippets' },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
    signature = { enabled = true },
})

-- TREESITTER
vim.pack.add({ { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } })
local parsers = {
    'bash',
    'c',
    'cpp',
    'tsx',
    'javascript',
    'typescript',
    'json',
    'html',
    'css',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc'
}
require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter based folds
    -- For more info on folds see `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })

-- KEYMAPS
vim.keymap.set("n", "<Esc>", "<cmd>noh<CR>")

-- tree
vim.keymap.set("n", "<C-b>", "<cmd>Neotree toggle<CR>")

-- movement
vim.keymap.set("n", "k", "kzz")
vim.keymap.set("n", "j", "jzz")
vim.keymap.set("n", "<C-k>", "<C-U>zz")
vim.keymap.set("n", "<C-j>", "<C-D>zz")

vim.keymap.set("n", "<C-h>", "b")
vim.keymap.set("n", "<C-l>", "w")

-- git
vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<cr>")

-- copy/paste
vim.keymap.set("v", "p", "P")
vim.keymap.set("v", "y", "ygv<Esc>")

-- history
vim.keymap.set("n", "<C-z>", "u")
vim.keymap.set("n", "<C-y>", "<C-R>")

-- comment
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment line' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment line' })

-- Visual Mode: Toggle comment for the selected block
vim.keymap.set('x', '<C-/>', 'gc', { remap = true, desc = 'Toggle comment selection' })
vim.keymap.set('x', '<C-_>', 'gc', { remap = true, desc = 'Toggle comment selection' })

-- save
vim.keymap.set("n", "<C-s>", "<cmd>:w<cr>")

-- tab
vim.keymap.set("n", "<Tab>", ">>")
vim.keymap.set("n", "<S-Tab>", "<<")
vim.keymap.set("i", "<S-Tab>", "<C-d>")
vim.keymap.set("v", "<S-Tab>", "<gv")
vim.keymap.set("v", "<Tab>", ">gv")

-- align
local function align()
    vim.ui.input(
        { prompt = "Align by: ", default = "" },
        function(val)
            if val == nil then
                return
            end

            vim.cmd("Tabularize /" .. val)
            local key = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
            vim.api.nvim_feedkeys(key, 'c', true)
        end
    )
end
vim.keymap.set('v', '<leader>v', function() align() end, { desc = "Align selection by a specific word" })

-- splits
vim.keymap.set("n", "<leader>w", "<C-w>s", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>W", "<C-w>v", { desc = "Split vertical" })

vim.keymap.set("n", "<leader>o", "<C-w>o", { desc = "Close other splits" })
vim.keymap.set("n", "<leader>q", "<C-w>q", { desc = "Close current split" })

vim.keymap.set("n", "<leader>k", "<C-w><Up>")
vim.keymap.set("n", "<leader>j", "<C-w><Down>")
vim.keymap.set("n", "<leader>h", "<C-w><Left>")
vim.keymap.set("n", "<leader>l", "<C-w><Right>")

-- tabs
local bufferline = require("bufferline")
vim.keymap.set("n", "<A-l>",  function() bufferline.cycle(1) end)
vim.keymap.set("n", "<A-h>",  function() bufferline.cycle(-1) end)
vim.keymap.set("n", ">",  "<cmd>BufferLineMoveNext<cr>")
vim.keymap.set("n", "<",  "<cmd>BufferLineMovePrev<cr>")
vim.keymap.set("n", "<C-w>",  function() bufferline.unpin_and_close() end)
vim.keymap.set("n", "<leader>tw", function () bufferline.close_others() end)

-- fff
vim.keymap.set("n", "<C-p>", function () require("fff").find_files() end)

-- Sessions
vim.keymap.set("n", "<leader>sl", "<cmd>SessionManager load_session<CR>")
vim.keymap.set("n", "<leader>sd", "<cmd>SessionManager delete_session<CR>")

-- LSP
vim.keymap.set("n", "<leader>hh", function() vim.lsp.buf.hover() end)

local conf = {
    layout = "telescope"
}
vim.keymap.set("n", "<C-A-o>", function() Snacks.picker.lsp_symbols(conf) end)
vim.keymap.set("n", "<F12>", function() Snacks.picker.lsp_references(conf) end)
vim.keymap.set("n", "<S-F12>", function() Snacks.picker.lsp_implementations(conf) end)
vim.keymap.set("n", "<A-F12>", function() Snacks.picker.lsp_definitions(conf) end)
vim.keymap.set("n", "<C-f>", function() Snacks.picker.lines() end)
vim.keymap.set("n", "<C-A-f>", function() Snacks.picker.grep() end)

-- diagnostics
vim.keymap.set("n", "<C-d>", function() require("trouble").toggle("diagnostics") end)

vim.keymap.set("n", "<F2>", function() vim.lsp.buf.rename() end)
