" quicklist.vim - Persist the result of list-like Ex commands to the quickfix list.
" Maintainer:	romainl <romainlafourcade@gmail.com>
" Version:	0.0.1
" License:	MIT
" Location:	plugin/quicklist.vim
" Website:	https://github.com/romainl/vim-quicklist

if exists("g:loaded_quicklist") || v:version < 703 || &compatible
    finish
endif
let g:loaded_quicklist = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:Get_raw_data_from(cmd)
    let raw_data = ""

    redir => raw_data
    execute "silent! " . a:cmd
    redir END

    return split(raw_data, '\n')
endfunction

function! Filter_raw_data_from(cmd)
    " expected return value : [[bufnr (-9999), filename (""), lnum (1), col (1), text ("")]]
    " :Changes
    if a:cmd == "changes"
        return map(map(filter(reverse(<SID>Get_raw_data_from(a:cmd)), 'v:val =~ "\\d"'), 'split(v:val, "\\s\\+")'), '[bufnr("%"), "", v:val[1], v:val[2] == 0 ? 1 : v:val[2], join(v:val[3:-1], " ")]')
    endif

    " :Clist :Llist
    if a:cmd == "clist" || a:cmd == "llist"
        let data = map(<SID>Get_raw_data_from(a:cmd), 'substitute(v:val, "^\\s*\\d\\+\\s\\+\\([^:]*\\):\\(\\d\\+\\)\\s\\+col\\s\\+\\(\\d\\+\\):\\s\\(.*$\\)", "-9999\\1§\\2§\\3§\\4", "")')
        return map(split(data, "§"), '[v:val[0], v:val[1], v:val[2], v:val[3] == 0 ? 1 : v:val[3], v:val[4]]')
    endif

    " :Marks
    if a:cmd == "marks"
        let data = map(filter(<SID>Get_raw_data_from(a:cmd), 'v:val !~ "^mark"'), 'substitute(v:val, "^\\s*\\(\\S\\)\\s\\+\\(\\d\\+\\)\\s\\+\\(\\d\\+\\)\\s\\(.*\\)$", "-9999§\\1§\\2§\\3§\\4", "")')
        let data_out = []
        for d in data
            let tmp = split(d, "§")
            if tmp[1] =~ '[A-Z0-9]'
                call add(data_out, [v:null, tmp[4], tmp[2] == 0 ? 1 : tmp[2], tmp[3] == 0 ? 1 : tmp[3], tmp[1]])
            else
                call add(data_out, [bufnr("%"), "", tmp[2] == 0 ? 1 : tmp[2], tmp[3] == 0 ? 1 : tmp[3], tmp[1]])
            endif
        endfor
        return data_out
    endif

    " :Dlist :Ilist
    if a:cmd == "dlist" || a:cmd == "ilist"
    endif

    " :Jumps
    if a:cmd == "jumps"
    endif

    " :Oldfiles
    if a:cmd == "oldfiles"
    endif

    " :Buffers :Files :Ls
    if a:cmd == "buffers" || a:cmd == "files" || a:cmd == "ls"
    endif

    " :Undolist
    if a:cmd == "undolist"
    endif

    " :Numbers
    if a:cmd == "numbers" || a:cmd == "#"
    endif

    " :Tags
    if a:cmd == "tags"
    endif
endfunction

function! Set_qf_list_from(cmd)
    let qf_entries = []

    for entry in Filter_raw_data_from(a:cmd)
        call add(qf_entries, { "bufnr" : entry[0], "filename" : entry[1], "lnum" : entry[2], "col" : entry[3], "text" : entry[4], "vcol" : 1 })
    endfor

    " Build the quickfix list from our results.
    call setqflist(qf_entries)

    " Open the quickfix window if there is something to show.
    cclose
    cwindow
endfunction

nnoremap <F5> :call Set_qf_list_from("marks")<CR>

let &cpo = s:save_cpo
