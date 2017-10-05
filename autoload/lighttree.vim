" Same as :exec cmd but with eventignore set for the duration
" to disable the autocommands used by NERDTree (BufEnter,
" BufLeave and VimEnter)
function! lighttree#exec(cmd)
    let old_ei = &ei
    set ei=BufEnter,BufLeave,VimEnter
    exec a:cmd
    let &ei = old_ei
endfunction

function! lighttree#echo(msg)
    redraw
    echomsg "LightTree: " . a:msg
endfunction

function! lighttree#echoError(msg)
    echohl errormsg
    call lighttree#echo(a:msg)
    echohl normal
endfunction

function! lighttree#echoWarning(msg)
    echohl warningmsg
    call lighttree#echo(a:msg)
    echohl normal
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
