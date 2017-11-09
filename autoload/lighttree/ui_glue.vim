function! lighttree#ui_glue#activate_node(node)
    call a:node.activate()
endfunction

function! lighttree#ui_glue#chCwd(node)
    try
        call a:node.path.changeToDir()
    catch /^NERDTree.PathChangeError/
        call lighttree#echoWarning("could not change cwd")
    endtry
endfunction

" changes the current root to the selected one
function! lighttree#ui_glue#chRoot(node)
    if a:node.path.isDirectory
        let b:NERDTree.root = a:node
    else
        call a:node.cacheParent()
        let b:NERDTree.root = a:node.parent
    endif

    call b:NERDTree.root.open()

    call b:NERDTree.render()
    call b:NERDTree.root.putCursorHere(0)
endfunction

" changes the current root to CWD
function! lighttree#ui_glue#chRootCwd()
    try
        let cwd = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("current directory does not exist.")
        return
    endtry
    call lighttree#ui_glue#chRoot(g:NERDTreeDirNode.New(cwd, b:NERDTree))
endfunction

" closes all childnodes of the current node
function! lighttree#ui_glue#closeChildren(node)
    if a:node.path.isDirectory
        call a:node.closeChildren()
        call b:NERDTree.render()
        call a:node.putCursorHere(0)
    endif
endfunction

" closes the parent dir of the current node
function! lighttree#ui_glue#closeParentDir(node)
    let parent = a:node.parent

    if !(parent ==# {})
        call parent.close()
        call b:NERDTree.render()
        call parent.putCursorHere(0)
    endif
endfunction

" toggles the help display
function! lighttree#ui_glue#displayHelp()
    call b:NERDTree.ui.toggleHelp()
    call b:NERDTree.render()
endfunction

" Move the cursor to the parent of the specified node. At the root, do
" nothing.
function! lighttree#ui_glue#jumpToParent(node)
    let l:parent = a:node.parent

    if !empty(l:parent)
        call l:parent.putCursorHere(1)
    else
        call lighttree#echo('could not jump to parent node')
    endif
endfunction

function! lighttree#ui_glue#jumpToRoot()
    call b:NERDTree.root.putCursorHere(1)
endfunction

function! lighttree#ui_glue#jumpToNextSibling(node)
    call lighttree#ui_glue#jumpToSibling(a:node, 1)
endfunction

function! lighttree#ui_glue#jumpToPrevSibling(node)
    call lighttree#ui_glue#jumpToSibling(a:node, 0)
endfunction

" moves the cursor to the sibling of the current node in the given direction
"
" Args:
" forward: 1 if the cursor should move to the next sibling, 0 if it should
" move back to the previous sibling
function! lighttree#ui_glue#jumpToSibling(currentNode, forward)
    let sibling = a:currentNode.findSibling(a:forward)

    if !empty(sibling)
        call sibling.putCursorHere(1)
    endif
endfunction

function! lighttree#ui_glue#openNodeRecursively(node)
    if a:node.path.isDirectory
        call lighttree#echo("Recursively opening node. Please wait...")
        call a:node.openRecursively()
        call b:NERDTree.render()
        redraw
        call lighttree#echo("Recursively opening node. Please wait... DONE")
    endif
endfunction

" Reloads the current root. All nodes below this will be lost and the root dir
" will be reloaded.
function! lighttree#ui_glue#refreshRoot()
    call lighttree#echo("Refreshing the root node. This could take a while...")
    call b:NERDTree.root.refresh()
    call b:NERDTree.render()
    redraw
    call lighttree#echo("Refreshing the root node. This could take a while... DONE")
endfunction

" refreshes the root for the current node
function! lighttree#ui_glue#refreshCurrent(node)
    let node = a:node
    if !node.path.isDirectory
        let node = node.parent
    endif

    call lighttree#echo("Refreshing node. This could take a while...")
    call node.refresh()
    call b:NERDTree.render()
    redraw
    call lighttree#echo("Refreshing node. This could take a while... DONE")
endfunction

function! lighttree#ui_glue#toggleIgnoreFilter()
    call b:NERDTree.ui.toggleIgnoreFilter()
endfunction

function! lighttree#ui_glue#toggleShowFiles()
    call b:NERDTree.ui.toggleShowFiles()
endfunction

" toggles the display of hidden files
function! lighttree#ui_glue#toggleShowHidden()
    call b:NERDTree.ui.toggleShowHidden()
endfunction

"moves the tree up a level
"
"Args:
"keepState: 1 if the current root should be left open when the tree is
"re-rendered
function! lighttree#ui_glue#upDir(keepState)
    let cwd = b:NERDTree.root.path.str({'format': 'UI'})
    if cwd ==# "/" || cwd =~# '^[^/]..$'
        call lighttree#echo("already at top dir")
    else
        if !a:keepState
            call b:NERDTree.root.close()
        endif

        let oldRoot = b:NERDTree.root

        if empty(b:NERDTree.root.parent)
            let path = b:NERDTree.root.path.getParent()
            let newRoot = g:NERDTreeDirNode.New(path, b:NERDTree)
            call newRoot.open()
            call newRoot.transplantChild(b:NERDTree.root)
            let b:NERDTree.root = newRoot
        else
            let b:NERDTree.root = b:NERDTree.root.parent
        endif

        call b:NERDTree.render()
        call oldRoot.putCursorHere(0)
    endif
endfunction

function! lighttree#ui_glue#upDirCurrentRootOpen()
    call lighttree#ui_glue#upDir(1)
endfunction

function! lighttree#ui_glue#upDirCurrentRootClosed()
    call lighttree#ui_glue#upDir(0)
endfunction
