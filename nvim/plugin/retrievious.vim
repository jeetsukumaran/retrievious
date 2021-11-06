

" Find from count directories up from current working directory
function! s:_find_up_n(count)
    let nlevels = a:count
    let root = getcwd()
    let rel = repeat("/..", nlevels)
    let cwd = substitute(root . "/" . rel . "/", "//", "/", "g")
    let prompt_path = fnamemodify(cwd, ":p:~")
    :lua require('telescope.builtin').find_files({cwd=vim.fn.eval("cwd"), prompt_title=vim.fn.eval("prompt_path")})
endfunction

" Grep from count directories up from current working directory
function! s:_grep_up_n(count)
    let nlevels = a:count
    let root = getcwd()
    let rel = repeat("/..", nlevels)
    let cwd = substitute(root . "/" . rel . "/", "//", "/", "g")
    let prompt_path = fnamemodify(cwd, ":p:~")
    :lua require('telescope.builtin').live_grep({cwd=vim.fn.eval("cwd"), prompt_title=vim.fn.eval("prompt_path")})
endfunction

" Grep from count directories up from current working directory
function! s:_grab_up_n(count)
    let nlevels = a:count
    let root = getcwd()
    let rel = repeat("/..", nlevels)
    let cwd = substitute(root . "/" . rel . "/", "//", "/", "g")
    let prompt_path = fnamemodify(cwd, ":p:~")
    execute "Telescope grab_lines cwd=" . cwd
endfunction

nnoremap <M-e>f. :<C-u>call <SID>_find_up_n(v:count)<CR>
nnoremap <M-e>g. :<C-u>call <SID>_grep_up_n(v:count)<CR>
nnoremap <M-p>l. :<C-u>call <SID>_grab_up_n(v:count)<CR>

function! s:_set_find_and_grep_keymaps()
    for nlevel in range(1, 9)
        execute "nnoremap <M-e>f" . nlevel . ". :<C-u>call <SID>_find_up_n(" . nlevel . ")<CR>"
        execute "nnoremap <M-e>g" . nlevel . ". :<C-u>call <SID>_grep_up_n(" . nlevel . ")<CR>"
        execute "nnoremap <M-p>l" . nlevel . ". :<C-u>call <SID>_grab_up_n(" . nlevel . ")<CR>"
    endfor
endfunction
call s:_set_find_and_grep_keymaps()

nnoremap <M-e>f~ <cmd>:lua require('telescope.builtin').find_files({cwd="~", prompt_title="~"})<CR>
nnoremap <M-e>g~ <cmd>:lua require('telescope.builtin').live_grep({cwd="~", prompt_title="~"})<CR>
nnoremap <M-p>l~ <cmd>:Telescope grab_lines cwd=~<CR>

nnoremap <M-e>b <cmd>Telescope buffers     <cr>
let g:ctrlp_map = '' " disable Ctrl-P automapping of <C-p>
nnoremap <C-p> <cmd>Telescope buffers     <cr>

nnoremap <M-e>rf <cmd>Telescope oldfiles    <cr>

nnoremap <M-e>g% <cmd>:lua require('telescope.builtin').live_grep({cwd=vim.fn.expand('%:p:h'), prompt_title=vim.fn.expand('%:p:h')})<CR>
nnoremap <M-e>gb <cmd>:lua require('telescope.builtin').live_grep({grep_open_files=true, prompt_title="buffers"})<CR>


