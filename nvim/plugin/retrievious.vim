
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

nnoremap <M-f>f. :<C-u>call <SID>_find_from_cwd(getcwd(), v:count)<CR>
nnoremap <M-f>f% :<C-u>call <SID>_find_from_cwd(expand("%:p:h"), v:count)<CR>
nnoremap <M-g>f. :<C-u>call <SID>_grep_up_n(getcwd(), v:count)<CR>
nnoremap <M-g>f% :<C-u>call <SID>_grep_up_n(expand("%:p:h"), v:count)<CR>
nnoremap <M-p>l. :<C-u>call <SID>_grab_up_n(getcwd(), v:count)<CR>
nnoremap <M-p>l% :<C-u>call <SID>_grab_up_n(expand("%:p:h"), v:count)<CR>

function! s:_set_find_and_grep_keymaps()
    for nlevel in range(1, 9)
        execute "nnoremap <M-f>f" . nlevel . ". :<C-u>call <SID>_find_from_cwd(getcwd(), " . nlevel . ")<CR>"
        execute "nnoremap <M-f>f" . nlevel . "% :<C-u>call <SID>_find_from_cwd(expand('%:p:h'), " . nlevel . ")<CR>"
        execute "nnoremap <M-g>f" . nlevel . ". :<C-u>call <SID>_grep_up_n(getcwd(), " . nlevel . ")<CR>"
        execute "nnoremap <M-g>f" . nlevel . "% :<C-u>call <SID>_grep_up_n(expand('%:p:h'), " . nlevel . ")<CR>"
        execute "nnoremap <M-p>l" . nlevel . ". :<C-u>call <SID>_grab_up_n(getcwd(), " . nlevel . ")<CR>"
        execute "nnoremap <M-p>l" . nlevel . "% :<C-u>call <SID>_grab_up_n(expand('%:p:h'), " . nlevel . ")<CR>"
    endfor
endfunction
call s:_set_find_and_grep_keymaps()

nnoremap <M-f>f~ <cmd>:lua require('telescope.builtin').find_files({cwd="~", prompt_title="~"})<CR>
nnoremap <M-g>f~ <cmd>:lua _telescope_grep({cwd="~", prompt_title="~"})<CR>
nnoremap <M-p>l~ <cmd>:Telescope grab_lines cwd=~<CR>

nnoremap <M-f>b <cmd>Telescope buffers     <cr>
nnoremap <C-p> <cmd>Telescope buffers      <cr>

nnoremap <M-r>f <cmd>Telescope oldfiles    <cr>
nnoremap <M-g>b <cmd>:lua _telescope_grep({grep_open_files=true, prompt_title="buffers"})<CR>


