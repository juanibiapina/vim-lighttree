if exists("g:loaded_nerdtree_exec_menuitem")
    finish
endif
let g:loaded_nerdtree_exec_menuitem = 1

call NERDTreeAddMenuItem({
            \ 'text': '(!)Execute file',
            \ 'shortcut': '!',
            \ 'callback': 'NERDTreeExecFile',
            \ 'isActiveCallback': 'NERDTreeExecFileActive' })

function! NERDTreeExecFileActive()
    let node = g:NERDTreeFileNode.GetSelected()
    return !node.path.isDirectory && node.path.isExecutable
endfunction

function! NERDTreeExecFile()
    let treenode = g:NERDTreeFileNode.GetSelected()
    echo "==========================================================\n"
    echo "Complete the command to execute (add arguments etc):\n"
    let cmd = treenode.path.str({'escape': 1})
    let cmd = input(':!', cmd . ' ')

    if cmd != ''
        exec ':!' . cmd
    else
        echo "Aborted"
    endif
endfunction
