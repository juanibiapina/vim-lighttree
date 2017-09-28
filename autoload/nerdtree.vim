if exists("g:loaded_nerdtree_autoload")
    finish
endif
let g:loaded_nerdtree_autoload = 1

"inits a window tree in the current buffer if appropriate
function! nerdtree#checkForBrowse(dir)
    if !isdirectory(a:dir)
        return
    endif

    " make netrw buffer disappear when lighttree buffer is opened
    setlocal bufhidden=wipe

    call g:NERDTreeCreator.RestoreOrCreateBuffer(a:dir)
endfunction

function! nerdtree#compareNodes(n1, n2)
    return a:n1.path.compareTo(a:n2.path)
endfunction

function! nerdtree#compareNodesBySortKey(n1, n2)
    let sortKey1 = a:n1.path.getSortKey()
    let sortKey2 = a:n2.path.getSortKey()

    let i = 0
    while i < min([len(sortKey1), len(sortKey2)])
        " Compare chunks upto common length.
        " If chunks have different type, the one which has
        " integer type is the lesser.
        if type(sortKey1[i]) == type(sortKey2[i])
            if sortKey1[i] <# sortKey2[i]
                return - 1
            elseif sortKey1[i] ># sortKey2[i]
                return 1
            endif
        elseif sortKey1[i] == type(0)
            return -1
        elseif sortKey2[i] == type(0)
            return 1
        endif
        let i = i + 1
    endwhile

    " Keys are identical upto common length.
    " The key which has smaller chunks is the lesser one.
    if len(sortKey1) < len(sortKey2)
        return -1
    elseif len(sortKey1) > len(sortKey2)
        return 1
    else
        return 0
    endif
endfunction

" Same as :exec cmd but with eventignore set for the duration
" to disable the autocommands used by NERDTree (BufEnter,
" BufLeave and VimEnter)
function! nerdtree#exec(cmd)
    let old_ei = &ei
    set ei=BufEnter,BufLeave,VimEnter
    exec a:cmd
    let &ei = old_ei
endfunction

function! nerdtree#has_opt(options, name)
    return has_key(a:options, a:name) && a:options[a:name] == 1
endfunction

function! nerdtree#loadClassFiles()
    runtime lib/nerdtree/path.vim
    runtime lib/nerdtree/menu_controller.vim
    runtime lib/nerdtree/menu_item.vim
    runtime lib/nerdtree/key_map.vim
    runtime lib/nerdtree/tree_file_node.vim
    runtime lib/nerdtree/tree_dir_node.vim
    runtime lib/nerdtree/creator.vim
    runtime lib/nerdtree/flag_set.vim
    runtime lib/nerdtree/nerdtree.vim
    runtime lib/nerdtree/ui.vim
    runtime lib/nerdtree/event.vim
    runtime lib/nerdtree/notifier.vim
endfunction

function! nerdtree#postSourceActions()
    call nerdtree#ui_glue#createDefaultBindings()

    "load all nerdtree plugins
    runtime! nerdtree_plugin/**/*.vim
endfunction

function! nerdtree#runningWindows()
    return has("win16") || has("win32") || has("win64")
endfunction

"A wrapper for :echo. Appends 'NERDTree:' on the front of all messages
"
"Args:
"msg: the message to echo
function! nerdtree#echo(msg)
    redraw
    echomsg "NERDTree: " . a:msg
endfunction

"Wrapper for nerdtree#echo, sets the message type to errormsg for this message
"Args:
"msg: the message to echo
function! nerdtree#echoError(msg)
    echohl errormsg
    call nerdtree#echo(a:msg)
    echohl normal
endfunction

"Wrapper for nerdtree#echo, sets the message type to warningmsg for this message
"Args:
"msg: the message to echo
function! nerdtree#echoWarning(msg)
    echohl warningmsg
    call nerdtree#echo(a:msg)
    echohl normal
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
