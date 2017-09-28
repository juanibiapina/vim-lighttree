if exists("g:loaded_nerdtree_ui_glue_autoload")
    finish
endif
let g:loaded_nerdtree_ui_glue_autoload = 1

function! nerdtree#ui_glue#createDefaultBindings()
    let s = '<SNR>' . s:SID() . '_'

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapActivateNode, 'scope': "DirNode", 'callback': s."activateDirNode" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapActivateNode, 'scope': "FileNode", 'callback': s."activateFileNode" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapActivateNode, 'scope': "all", 'callback': s."activateAll" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapOpenRecursively, 'scope': "DirNode", 'callback': s."openNodeRecursively" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapUpdir, 'scope': "all", 'callback': s."upDirCurrentRootClosed" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapUpdirKeepOpen, 'scope': "all", 'callback': s."upDirCurrentRootOpen" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapChangeRoot, 'scope': "Node", 'callback': s."chRoot" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapChdir, 'scope': "Node", 'callback': s."chCwd" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCWD, 'scope': "all", 'callback': "nerdtree#ui_glue#chRootCwd" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapRefreshRoot, 'scope': "all", 'callback': s."refreshRoot" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapRefresh, 'scope': "Node", 'callback': s."refreshCurrent" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapHelp, 'scope': "all", 'callback': s."displayHelp" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleHidden, 'scope': "all", 'callback': s."toggleShowHidden" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleFilters, 'scope': "all", 'callback': s."toggleIgnoreFilter" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapToggleFiles, 'scope': "all", 'callback': s."toggleShowFiles" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCloseDir, 'scope': "Node", 'callback': s."closeCurrentDir" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapCloseChildren, 'scope': "DirNode", 'callback': s."closeChildren" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapMenu, 'scope': "Node", 'callback': s."showMenu" })

    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpParent, 'scope': "Node", 'callback': s."jumpToParent" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpFirstChild, 'scope': "Node", 'callback': s."jumpToFirstChild" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpLastChild, 'scope': "Node", 'callback': s."jumpToLastChild" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpRoot, 'scope': "all", 'callback': s."jumpToRoot" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpNextSibling, 'scope': "Node", 'callback': s."jumpToNextSibling" })
    call NERDTreeAddKeyMap({ 'key': g:NERDTreeMapJumpPrevSibling, 'scope': "Node", 'callback': s."jumpToPrevSibling" })
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
        call nerdtree#echoWarning("could not change cwd")
    endtry
endfunction

" changes the current root to the selected one
function! s:chRoot(node)
    call b:NERDTree.changeRoot(a:node)
endfunction

" changes the current root to CWD
function! nerdtree#ui_glue#chRootCwd()
    try
        let cwd = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call nerdtree#echo("current directory does not exist.")
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
function! s:closeCurrentDir(node)
    let parent = a:node.parent
    while g:NERDTreeCascadeOpenSingleChildDir && !parent.isRoot()
        let childNodes = parent.getVisibleChildren()
        if len(childNodes) == 1 && childNodes[0].path.isDirectory
            let parent = parent.parent
        else
            break
        endif
    endwhile
    if parent ==# {} || parent.isRoot()
        call nerdtree#echo("cannot close tree root")
    else
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

function! s:findAndRevealPath()
    try
        let p = g:NERDTreePath.New(expand("%:p"))
    catch /^NERDTree.InvalidArgumentsError/
        call nerdtree#echo("no file for the current buffer")
        return
    endtry

    if p.isUnixHiddenPath()
        let showhidden=g:NERDTreeShowHidden
        let g:NERDTreeShowHidden = 1
    endif

    try
        let rootDir = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call nerdtree#echo("current directory does not exist.")
        let rootDir = p.getParent()
    endtry

    if p.isUnder(rootDir)
        call g:NERDTreeCreator.RestoreOrCreateBuffer(rootDir.str())
    else
        call g:NERDTreeCreator.RestoreOrCreateBuffer(p.getParent().str())
    endif

    let node = b:NERDTree.root.reveal(p)
    call b:NERDTree.render()
    call node.putCursorHere(1)

    if p.isUnixHiddenFile()
        let g:NERDTreeShowHidden = showhidden
    endif
endfunction

" Args:
" direction: 0 if going to first child, 1 if going to last
function! s:jumpToChild(currentNode, direction)
    if a:currentNode.isRoot()
        return nerdtree#echo("cannot jump to " . (a:direction ? "last" : "first") .  " child")
    end
    let dirNode = a:currentNode.parent
    let childNodes = dirNode.getVisibleChildren()

    let targetNode = childNodes[0]
    if a:direction
        let targetNode = childNodes[len(childNodes) - 1]
    endif

    if targetNode.equals(a:currentNode)
        let siblingDir = a:currentNode.parent.findOpenDirSiblingWithVisibleChildren(a:direction)
        if siblingDir != {}
            let indx = a:direction ? siblingDir.getVisibleChildCount()-1 : 0
            let targetNode = siblingDir.getChildByIndex(indx, 1)
        endif
    endif

    call targetNode.putCursorHere(1)
endfunction


"this is needed since I cant figure out how to invoke dict functions from a
"key map
function! nerdtree#ui_glue#invokeKeyMap(key)
    call g:NERDTreeKeyMap.Invoke(a:key)
endfunction

" wrapper for the jump to child method
function! s:jumpToFirstChild(node)
    call s:jumpToChild(a:node, 0)
endfunction

" wrapper for the jump to child method
function! s:jumpToLastChild(node)
    call s:jumpToChild(a:node, 1)
endfunction

" Move the cursor to the parent of the specified node. For a cascade, move to
" the parent of the cascade's highest node. At the root, do nothing.
function! s:jumpToParent(node)
    let l:parent = a:node.parent

    " If "a:node" represents a directory, back out of its cascade.
    if a:node.path.isDirectory
        while !empty(l:parent) && !l:parent.isRoot()
            if index(l:parent.getCascade(), a:node) >= 0
                let l:parent = l:parent.parent
            else
                break
            endif
        endwhile
    endif

    if !empty(l:parent)
        call l:parent.putCursorHere(1)
    else
        call nerdtree#echo('could not jump to parent node')
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
    call nerdtree#echo("Recursively opening node. Please wait...")
    call a:node.openRecursively()
    call b:NERDTree.render()
    redraw
    call nerdtree#echo("Recursively opening node. Please wait... DONE")
endfunction

" Reloads the current root. All nodes below this will be lost and the root dir
" will be reloaded.
function! s:refreshRoot()
    call nerdtree#echo("Refreshing the root node. This could take a while...")
    call b:NERDTree.root.refresh()
    call b:NERDTree.render()
    redraw
    call nerdtree#echo("Refreshing the root node. This could take a while... DONE")
endfunction

" refreshes the root for the current node
function! s:refreshCurrent(node)
    let node = a:node
    if !node.path.isDirectory
        let node = node.parent
    endif

    call nerdtree#echo("Refreshing node. This could take a while...")
    call node.refresh()
    call b:NERDTree.render()
    redraw
    call nerdtree#echo("Refreshing node. This could take a while... DONE")
endfunction

function! nerdtree#ui_glue#setupCommands()
    command! -n=? -complete=dir -bar LightTree :call g:NERDTreeCreator.RestoreOrCreateBuffer('<args>')
    command! -n=0 -bar LightTreeFind call s:findAndRevealPath()
endfunction

" Function: s:SID()   {{{1
function s:SID()
    if !exists("s:sid")
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

function! s:showMenu(node)
    let mc = g:NERDTreeMenuController.New(g:NERDTreeMenuItem.AllEnabled())
    call mc.showMenu()
endfunction

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
function! nerdtree#ui_glue#upDir(keepState)
    let cwd = b:NERDTree.root.path.str({'format': 'UI'})
    if cwd ==# "/" || cwd =~# '^[^/]..$'
        call nerdtree#echo("already at top dir")
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
    call nerdtree#ui_glue#upDir(1)
endfunction

function! s:upDirCurrentRootClosed()
    call nerdtree#ui_glue#upDir(0)
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
