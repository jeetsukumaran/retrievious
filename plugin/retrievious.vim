" Global Variables and Settings {{{1
let g:retrievious_leader_key = get(g:, "retrievious_leader_key", "<M-r>")
let g:retrievious_global_search_paths1 = get(g:, "retrievious_global_search_paths1", $RETRIEVIOUS_GLOBAL_SEARCH_PATHS1)
let g:retrievious_global_search_paths2 = get(g:, "retrievious_global_search_paths2", $RETRIEVIOUS_GLOBAL_SEARCH_PATHS2)
let g:retrievious_global_path_separator = get(g:, "retrievious_global_path_separator", $RETRIEVIOUS_GLOBAL_PATH_SEPARATOR)
" }}}1

" Keybinds {{{1

" Supporting Functions {{{2

" Operational Functions {{{3
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
" }}}3 Operational Functions

" Keymapping Functions {{{3

" Handles all [count] mappings for targets: '.', '%'
function! s:_set_find_and_grep_keymaps(key_seq, target, fn_name, cwd)
    execute "nnoremap " . g:retrievious_leader_key . a:key_seq . a:target . " :<C-u>call " . a:fn_name . "(" . a:cwd . ", v:count)<CR>"
    for nlevel in range(1, 9)
        execute "nnoremap " . g:retrievious_leader_key . a:key_seq . nlevel . a:target . " :<C-u>call " . a:fn_name . "(" . a:cwd . ", " . nlevel . ")<CR>"
    endfor
endfunction
" }}}3 Keymapping Functions

" }}}2 Supporting Functions

" Key Mappings {{{2

" #### 1.1.1. Retrieve [to visit]: [Find] [File]
call s:_set_find_and_grep_keymaps("f", "~", "<SID>_find_from_cwd", "'~'")
execute ":nnoremap <silent> " . g:retrievious_leader_key . "<M-f> :lua require('telescope.builtin').find_files({search_dirs=vim.fn.split(vim.g.retrievious_global_search_paths1, vim.g.retrievious_global_path_separator)})<CR>"
execute ":nnoremap <silent> " . g:retrievious_leader_key . "<C-f> :lua require('telescope.builtin').find_files({search_dirs=vim.fn.split(vim.g.retrievious_global_search_paths2, vim.g.retrievious_global_path_separator)})<CR>"
call s:_set_find_and_grep_keymaps("f", ".", "<SID>_find_from_cwd", "getcwd()")
call s:_set_find_and_grep_keymaps("f", "%", "<SID>_find_from_cwd", "expand('%:p:h')")

" #### 1.1.2. Retrieve [to visit]: [Find] Directory
" TODO

" #### 1.1.3 Retrieve: [Find] Buffer
execute "nnoremap " . g:retrievious_leader_key . "b <cmd>Telescope buffers<CR>"
nnoremap <C-p> <cmd>Telescope buffers<CR>

" #### 1.1.4 Retrieve: [Find] Lines in Buffer
execute ":nnoremap " . g:retrievious_leader_key . "lb :<C-u>Telescope current_buffer_fuzzy_find<CR>"

" #### 1.2.1. Retrieve [to visit]: Grep [File]
call s:_set_find_and_grep_keymaps("g", "~", "<SID>_grep_up_n", "'~'")
execute ":nnoremap <silent> " . g:retrievious_leader_key . "<M-g> :lua require('telescope.builtin').live_grep({search_dirs=vim.fn.split(vim.g.retrievious_global_search_paths1, vim.g.retrievious_global_path_separator)})<CR>"
execute ":nnoremap <silent> " . g:retrievious_leader_key . "<C-g> :lua require('telescope.builtin').live_grep({search_dirs=vim.fn.split(vim.g.retrievious_global_search_paths2, vim.g.retrievious_global_path_separator)})<CR>"
call s:_set_find_and_grep_keymaps("g", ".", "<SID>_grep_up_n", "getcwd()")
call s:_set_find_and_grep_keymaps("g", "%", "<SID>_grep_up_n", "expand('%:p:h')")

" #### 1.2.2. Retrieve [to visit]: Grep (Open) Buffers
execute "nnoremap " . g:retrievious_leader_key . "gb <cmd>:lua require('telescope.builtin').live_grep({grep_open_files=true, prompt_title='buffers'})<CR>"
execute "nnoremap " . g:retrievious_leader_key . "/  <cmd>:lua require('telescope.builtin').live_grep({grep_open_files=true, prompt_title='buffers'})<CR>"

" #### 1.2.3. Retrieve [to visit]: Grep Lines (in Current Buffer)
execute "nnoremap " . g:retrievious_leader_key . "gl :lua require('telescope.builtin').live_grep({search_dirs={vim.fn.expand('%:p')}})<CR>"
execute "nnoremap " . g:retrievious_leader_key . "\ :lua require('telescope.builtin').live_grep({search_dirs={vim.fn.expand('%:p')}})<CR>"

" #### 1.3.1. Retrieve [to visit]: Recent
execute "nnoremap " . g:retrievious_leader_key . "rf <cmd>Telescope oldfiles<CR>"

" #### 2.1.1. Retrieve to *p*aste: [Find] [File]
" TODO

" #### 2.1.2. Retrieve to *p*aste: [Find] Directory
" TODO

" #### 2.2.1. Retrieve to *p*aste: Lines
" execute "nnoremap " . g:retrievious_leader_key . "plb <NOP>"
execute "nnoremap " . g:retrievious_leader_key . "plb  <cmd>:lua require('telescope').extensions.grab_lines.grab_lines({grep_open_files=true, prompt_time='buffers'})<CR>"
" :lua require('telescope').extensions.grab_lines.grab_lines({cwd=vim.fn.eval("cwd"), prompt_title=vim.fn.eval("prompt_path")})

call s:_set_find_and_grep_keymaps("pl", "~", "<SID>_grab_up_n", "'~'")
call s:_set_find_and_grep_keymaps("pl", ".", "<SID>_grab_up_n", "getcwd()")
call s:_set_find_and_grep_keymaps("pl", "%", "<SID>_grab_up_n", "expand('%:p:h')")

" #### 2.3.1. Retrieve to *p*aste: *R*ecent *f*iles, *d*irectories, and *c*ommands

" }}}2 Key Mappings

" }}}1 Keybinds
