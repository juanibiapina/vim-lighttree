function! lighttree#ui_glue#createDefaultBindings()
    let s = '<SNR>' . s:SID() . '_'

    call lighttree#keymap#create(g:LightTreeMapActivateNode, "DirNode", s."activateDirNode")
    call lighttree#keymap#create(g:LightTreeMapActivateNode, "FileNode", s."activateFileNode")
    call lighttree#keymap#create(g:LightTreeMapActivateNode, "all", s."activateAll")

    call lighttree#keymap#create(g:LightTreeMapOpenRecursively, "DirNode", s."openNodeRecursively")

    call lighttree#keymap#create(g:LightTreeMapUpdir, "all", s."upDirCurrentRootClosed")
    call lighttree#keymap#create(g:LightTreeMapUpdirKeepOpen, "all", s."upDirCurrentRootOpen")
    call lighttree#keymap#create(g:LightTreeMapChangeRoot, "Node", s."chRoot")

    call lighttree#keymap#create(g:LightTreeMapChdir, "Node", s."chCwd")

    call lighttree#keymap#create(g:LightTreeMapCWD, "all", "lighttree#ui_glue#chRootCwd")

    call lighttree#keymap#create(g:LightTreeMapRefreshRoot, "all", s."refreshRoot")
    call lighttree#keymap#create(g:LightTreeMapRefresh, "Node", s."refreshCurrent")

    call lighttree#keymap#create(g:LightTreeMapHelp, "all", s."displayHelp")
    call lighttree#keymap#create(g:LightTreeMapToggleHidden, "all", s."toggleShowHidden")
    call lighttree#keymap#create(g:LightTreeMapToggleFilters, "all", s."toggleIgnoreFilter")
    call lighttree#keymap#create(g:LightTreeMapToggleFiles, "all", s."toggleShowFiles")

    call lighttree#keymap#create(g:LightTreeMapCloseDir, "Node", s."closeParentDir")
    call lighttree#keymap#create(g:LightTreeMapCloseChildren, "DirNode", s."closeChildren")

    call lighttree#keymap#create(g:LightTreeMapMenu, "Node", "lighttree#menu#show")

    call lighttree#keymap#create(g:LightTreeMapJumpParent, "Node", s."jumpToParent")
    call lighttree#keymap#create(g:LightTreeMapJumpRoot, "all", s."jumpToRoot")
    call lighttree#keymap#create(g:LightTreeMapJumpNextSibling, "Node", s."jumpToNextSibling")
    call lighttree#keymap#create(g:LightTreeMapJumpPrevSibling, "Node", s."jumpToPrevSibling")
endfunction


"SECTION: Interface bindings {{{1
"============================================================

"handle the user activating a tree node
function! s:activateDirNode(node)
    call a:node.activate()
endfunction

"handle the user activating a tree node
function! s:activateFileNode(node)
    call a:node.activate()
endfunction

function! s:chCwd(node)
    try
        call a:node.path.changeToDir()
    catch /^NERDTree.PathChangeError/
        call lighttree#echoWarning("could not change cwd")
    endtry
endfunction

" changes the current root to the selected one
function! s:chRoot(node)
    call b:NERDTree.changeRoot(a:node)
endfunction

" changes the current root to CWD
function! lighttree#ui_glue#chRootCwd()
    try
        let cwd = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("current directory does not exist.")
        return
    endtry
    call s:chRoot(g:NERDTreeDirNode.New(cwd, b:NERDTree))
endfunction

" closes all childnodes of the current node
function! s:closeChildren(node)
    call a:node.closeChildren()
    call b:NERDTree.render()
    call a:node.putCursorHere(0)
endfunction

" closes the parent dir of the current node
function! s:closeParentDir(node)
    let parent = a:node.parent

    if !(parent ==# {})
        call parent.close()
        call b:NERDTree.render()
        call parent.putCursorHere(0)
    endif
endfunction

" toggles the help display
function! s:displayHelp()
    call b:NERDTree.ui.toggleHelp()
    call b:NERDTree.render()
endfunction

" Move the cursor to the parent of the specified node. At the root, do
" nothing.
function! s:jumpToParent(node)
    let l:parent = a:node.parent

    if !empty(l:parent)
        call l:parent.putCursorHere(1)
    else
        call lighttree#echo('could not jump to parent node')
    endif
endfunction

" moves the cursor to the root node
function! s:jumpToRoot()
    call b:NERDTree.root.putCursorHere(1)
endfunction

function! s:jumpToNextSibling(node)
    call s:jumpToSibling(a:node, 1)
endfunction

function! s:jumpToPrevSibling(node)
    call s:jumpToSibling(a:node, 0)
endfunction

" moves the cursor to the sibling of the current node in the given direction
"
" Args:
" forward: 1 if the cursor should move to the next sibling, 0 if it should
" move back to the previous sibling
function! s:jumpToSibling(currentNode, forward)
    let sibling = a:currentNode.findSibling(a:forward)

    if !empty(sibling)
        call sibling.putCursorHere(1)
    endif
endfunction

function! s:openNodeRecursively(node)
    call lighttree#echo("Recursively opening node. Please wait...")
    call a:node.openRecursively()
    call b:NERDTree.render()
    redraw
    call lighttree#echo("Recursively opening node. Please wait... DONE")
endfunction

" Reloads the current root. All nodes below this will be lost and the root dir
" will be reloaded.
function! s:refreshRoot()
    call lighttree#echo("Refreshing the root node. This could take a while...")
    call b:NERDTree.root.refresh()
    call b:NERDTree.render()
    redraw
    call lighttree#echo("Refreshing the root node. This could take a while... DONE")
endfunction

" refreshes the root for the current node
function! s:refreshCurrent(node)
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

" Function: s:SID()   {{{1
function s:SID()
    if !exists("s:sid")
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

function! s:toggleIgnoreFilter()
    call b:NERDTree.ui.toggleIgnoreFilter()
endfunction

function! s:toggleShowFiles()
    call b:NERDTree.ui.toggleShowFiles()
endfunction

" toggles the display of hidden files
function! s:toggleShowHidden()
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

function! s:upDirCurrentRootOpen()
    call lighttree#ui_glue#upDir(1)
endfunction

function! s:upDirCurrentRootClosed()
    call lighttree#ui_glue#upDir(0)
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
