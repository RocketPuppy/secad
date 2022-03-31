{ neovim, vimPlugins }:
neovim.override {
  configure = {
  customRC = ''
    set encoding=utf-8

    let g:ale_completion_enabled = 1
    set omnifunc=ale#completion#OmniFunc
    let g:ale_completion_autoimport = 1
    let g:ale_sign_error = "✗"
    let g:ale_sign_warning = "⚠"
    let g:ale_linters = { 'rust': ['analyzer'] }
    let g:ale_fixers = { 'rust': ['rustfmt'] }
    let g:ale_fix_on_save = 1
    let g:ale_default_navigation = "split"
    let g:ale_floating_preview = 1
    let g:ale_close_preview_on_insert = 1
    let g:ale_cursor_detail = 1
    let g:ale_echo_delay = 100
    let g:ale_echo_cursor = 1

    nnoremap <C-b> :ALEGoToDefinition<CR>
    nnoremap <C-g> :ALEFindReferences<CR>
    inoremap <silent> <C-Space> <C-\><C-O>:ALEComplete<CR>
    nnoremap <Space><Space> :ALESymbolSearch
    inoremap <silent> <C-q> <C-\><C-O>:ALEHover<CR>
    nnoremap <S-F6> :ALERename<CR>
    nnoremap <Space><Enter> :ALECodeAction<CR>
    nnoremap <C-n> :ALENextWrap<CR>
    nnoremap <C-q> :ALEDetail<CR>

    set nocompatible
    set shiftwidth=4
    set background=dark
    set autoindent
    set tabstop=4
    set softtabstop=4
    set showmatch
    set ruler
    set incsearch
    set ignorecase
    set smartcase
    set number
    set numberwidth=3
    set relativenumber
    set expandtab
    set scrolloff=10
    set showcmd
    set novisualbell
    set noerrorbells
    set tw=0
    set wm=0
    set switchbuf+=usetab,newtab
    set clipboard=unnamedplus
    " Status line
    set laststatus=2
    set statusline=
    set statusline+=%F
    set statusline+=%h%m%r%w
    set statusline+=%=
    set statusline+=%-14(%l,%c%V%)
    set statusline+=%{'Buf_'}
    set statusline+=%-5.3n
    set statusline+=%<%P
    " end status line
    " Show trailing whitespace
    set list
    set listchars=tab:>-,trail:.,extends:#,nbsp:.

    set backspace=indent,eol,start

    set clipboard=unnamedplus

    set cursorline

    autocmd QuickFixCmdPost *grep* cwindow

    syntax enable
    filetype plugin on
    filetype plugin indent on

    nnoremap  :UndotreeToggle<cr>

    lua << EOF
    local nvim_lsp = require'lspconfig'

    local on_attach = function(client)
        require'completion'.on_attach(client)
    end

    nvim_lsp.rust_analyzer.setup({
        on_attach=on_attach,
        settings = {
            ["rust-analyzer"] = {
                assist = {
                    importGranularity = "module",
                    importPrefix = "by_self",
                },
                cargo = {
                    loadOutDirsFromCheck = true
                },
                procMacro = {
                    enable = true
                },
            }
        }
    })
    EOF
  '';
    packages.myVimPackage = with vimPlugins; {
      # see examples below how to use custom packages
      start = [
        rust-vim # rust syntax, formatting, rustplay...
        nvim-lspconfig
        rust-tools-nvim
        fugitive
        vinegar
        undotree
      ];
      opt = [ ];
    };
  };
}
