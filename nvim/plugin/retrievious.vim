" Supporting Functions {{{1

" Operational Functions {{{2
lua << EOF
-- Use `live_grep_raw` if available, otherwise fall back to `live_grep`
-- - `live_grep_raw` is IMHO a more useful interface, allowing you to specify
--   file types in the query prompt (e.g., ``-tpy to_csv.*index``).
-- - Currently `live_grep_raw` is a standalone plugin
--      (https://github.com/nvim-telescope/telescope-live-grep-raw.nvim)
--   but hopefully/probably/soon will be incorporated into Telescope builtin.
local has_telescope_live_grep_raw, telescope_live_grep_raw = pcall(require, "telescope._extensions.live_grep_raw")
function _G._telescope_grep(opts)
    if has_telescope_live_grep_raw then
        require('telescope').extensions.live_grep_raw.live_grep_raw(opts)
    else
        require('telescope.builtin').live_grep(opts)
    end
end
EOF

" Find from count directories up from current working directory
function! s:_find_from_cwd(root, count)
    let nlevels = a:count
    let rel = repeat("/..", nlevels)
    let cwd = substitute(a:root . "/" . rel . "/", "//", "/", "g")
    let prompt_path = fnamemodify(cwd, ":p:~")
    :lua require('telescope.builtin').find_files({cwd=vim.fn.eval("cwd"), prompt_title=vim.fn.eval("prompt_path")})
endfunction

" Grep from count directories up from current working directory
function! s:_grep_up_n(root, count)
    let nlevels = a:count
    let rel = repeat("/..", nlevels)
    let cwd = substitute(a:root . "/" . rel . "/", "//", "/", "g")
    let prompt_path = fnamemodify(cwd, ":p:~")
    " :lua require('telescope.builtin').live_grep({cwd=vim.fn.eval("cwd"), prompt_title=vim.fn.eval("prompt_path")})
    " :lua require('telescope').extensions.live_grep_raw.live_grep_raw({cwd=vim.fn.eval("cwd"), prompt_title=vim.fn.eval("prompt_path")})
    :lua _telescope_grep({cwd=vim.fn.eval("cwd"), prompt_title=vim.fn.eval("prompt_path")})
endfunction

" Grep from count directories up from current working directory
function! s:_grab_up_n(root, count)
    let nlevels = a:count
    let rel = repeat("/..", nlevels)
    let cwd = substitute(a:root . "/" . rel . "/", "//", "/", "g")
    let prompt_path = fnamemodify(cwd, ":p:~")
    execute "Telescope grab_lines cwd=" . cwd
endfunction
" }}}2 Operational Functions

" Keymapping Functions {{{2

" Handles all [count] mappings for targets: '.', '%'
function! s:_set_find_and_grep_keymaps(key_seq, target, fn_name, cwd)
    execute "nnoremap <M-r>" . a:key_seq . a:target . " :<C-u>call " . a:fn_name . "(" . a:cwd . ", v:count)<CR>"
    for nlevel in range(1, 9)
        execute "nnoremap <M-r>" . a:key_seq . nlevel . a:target . " :<C-u>call " . a:fn_name . "(" . a:cwd . ", " . nlevel . ")<CR>"
    endfor
endfunction
" }}}2 Keymapping Functions

" }}}1 Supporting Functions

" Key Mappings {{{1

" #### 1.1.1. Retrieve [to visit]: [Find] [File]
call s:_set_find_and_grep_keymaps("", "~", "<SID>_find_from_cwd", "'~'")
call s:_set_find_and_grep_keymaps("", ".", "<SID>_find_from_cwd", "getcwd()")
call s:_set_find_and_grep_keymaps("", "%", "<SID>_find_from_cwd", "expand('%:p:h')")

" #### 1.1.2. Retrieve [to visit]: [Find] Directory
" TODO

" #### 1.1.3 Retrieve: [Find] Buffer
nnoremap <M-r>b <cmd>Telescope buffers<CR>
nnoremap <C-p> <cmd>Telescope buffers<CR>

" #### 1.1.4 Retrieve: [Find] Lines
nnoremap <M-r>l :<C-u>Telescope current_buffer_fuzzy_find<CR>

" #### 1.2.1. Retrieve [to visit]: Grep [File]
call s:_set_find_and_grep_keymaps("g", "~", "<SID>_grep_up_n", "'~'")
call s:_set_find_and_grep_keymaps("g", ".", "<SID>_grep_up_n", "getcwd()")
call s:_set_find_and_grep_keymaps("g", "%", "<SID>_grep_up_n", "expand('%:p:h')")

" #### 1.2.2. Retrieve [to visit]: Grep [Buffer]
nnoremap <M-r>gb <cmd>:lua _telescope_grep({grep_open_files=true, prompt_title="buffers"})<CR>

" #### 1.3.1. Retrieve [to visit]: Recent
nnoremap <M-r>rf <cmd>Telescope oldfiles<CR>

" #### 2.1.1. Retrieve to *p*aste: [Find] [File]
" TODO

" #### 2.1.2. Retrieve to *p*aste: [Find] Directory
" TODO

" #### 2.2.1. Retrieve to *p*aste: Lines
call s:_set_find_and_grep_keymaps("pl", "~", "<SID>_grab_up_n", "'~'")
call s:_set_find_and_grep_keymaps("pl", ".", "<SID>_grab_up_n", "getcwd()")
call s:_set_find_and_grep_keymaps("pl", "%", "<SID>_grab_up_n", "expand('%:p:h')")

" #### 2.3.1. Retrieve to *p*aste: *R*ecent *f*iles, *d*irectories, and *c*ommands

" }}}1 Key Mappings

