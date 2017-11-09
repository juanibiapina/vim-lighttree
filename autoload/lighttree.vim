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

function! lighttree#find_and_reveal_path()
    try
        let p = g:NERDTreePath.New(expand("%:p"))
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("no file for the current buffer")
        return
    endtry

    if p.isUnixHiddenPath()
        let showhidden=g:LightTreeShowHidden
        let g:LightTreeShowHidden = 1
    endif

    try
        let rootDir = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("current directory does not exist.")
        let rootDir = p.getParent()
    endtry

    if p.isUnder(rootDir)
        call lighttree#buffer#restore_or_create(rootDir.str())
    else
        call lighttree#buffer#restore_or_create(p.getParent().str())
    endif

    let node = b:tree.root.reveal(p)
    call b:tree.render()
    call node.putCursorHere(1)

    if p.isUnixHiddenFile()
        let g:LightTreeShowHidden = showhidden
    endif
endfunction
