if exists("g:loaded_nerdtree_fs_menu")
    finish
endif
let g:loaded_nerdtree_fs_menu = 1

call NERDTreeAddMenuItem({'text': '(a)dd a childnode', 'shortcut': 'a', 'callback': 'NERDTreeAddNode'})
call NERDTreeAddMenuItem({'text': '(m)ove the current node', 'shortcut': 'm', 'callback': 'NERDTreeMoveNode'})
call NERDTreeAddMenuItem({'text': '(d)elete the current node', 'shortcut': 'd', 'callback': 'NERDTreeDeleteNode'})

if has("gui_mac") || has("gui_macvim") || has("mac")
    call NERDTreeAddMenuItem({'text': '(r)eveal in Finder the current node', 'shortcut': 'r', 'callback': 'NERDTreeRevealInFinder'})
    call NERDTreeAddMenuItem({'text': '(o)pen the current node with system editor', 'shortcut': 'o', 'callback': 'NERDTreeExecuteFile'})
    call NERDTreeAddMenuItem({'text': '(q)uicklook the current node', 'shortcut': 'q', 'callback': 'NERDTreeQuickLook'})
endif

if g:NERDTreePath.CopyingSupported()
    call NERDTreeAddMenuItem({'text': '(c)opy the current node', 'shortcut': 'c', 'callback': 'NERDTreeCopyNode'})
endif

if has("unix") || has("osx")
    call NERDTreeAddMenuItem({'text': '(l)ist the current node', 'shortcut': 'l', 'callback': 'NERDTreeListNode'})
else
    call NERDTreeAddMenuItem({'text': '(l)ist the current node', 'shortcut': 'l', 'callback': 'NERDTreeListNodeWin32'})
endif

"deletes the buffer with given bufnum
function! s:deleteBuffer(bufnum)
    " 1. ensure that all windows which display the just deleted filename
    " now display an empty buffer (so a layout is preserved).
    " Is not it better to close single tabs with this file only ?
    let s:originalTabNumber = tabpagenr()
    let s:originalWindowNumber = winnr()
    exec "tabdo windo if winbufnr(0) == " . a:bufnum . " | exec ':enew! ' | endif"
    exec "tabnext " . s:originalTabNumber
    exec s:originalWindowNumber . "wincmd w"
    " 3. We don't need a previous buffer anymore
    exec "bwipeout! " . a:bufnum
endfunction

"replaces the buffer with the given bufnum with a new one
function! s:replaceBuffer(bufnum, newFileName)
    let quotedFileName = fnameescape(a:newFileName)
    " 1. ensure that a new buffer is loaded
    exec "badd " . quotedFileName
    " 2. ensure that all windows which display the just deleted filename
    " display a buffer for a new filename.
    let s:originalTabNumber = tabpagenr()
    let s:originalWindowNumber = winnr()
    let editStr = g:NERDTreePath.New(a:newFileName).str({'format': 'Edit'})
    exec "tabdo windo if winbufnr(0) == " . a:bufnum . " | exec ':e! " . editStr . "' | endif"
    exec "tabnext " . s:originalTabNumber
    exec s:originalWindowNumber . "wincmd w"
    " 3. We don't need a previous buffer anymore
    exec "bwipeout! " . a:bufnum
endfunction

function! NERDTreeAddNode()
    let curDirNode = g:NERDTreeDirNode.GetSelected()

    let newNodeName = input("Add a childnode\n".
                          \ "==========================================================\n".
                          \ "Enter the dir/file name to be created. Dirs end with a '/'\n" .
                          \ "", curDirNode.path.str() . g:NERDTreePath.Slash(), "file")

    if newNodeName ==# ''
        call lighttree#echo("Node Creation Aborted.")
        return
    endif

    try
        let newPath = g:NERDTreePath.Create(newNodeName)
        let parentNode = b:NERDTree.root.findNode(newPath.getParent())

        let newTreeNode = g:NERDTreeFileNode.New(newPath, b:NERDTree)
        if empty(parentNode)
            call b:NERDTree.root.refresh()
            call b:NERDTree.render()
        elseif parentNode.isOpen || !empty(parentNode.children)
            call parentNode.addChild(newTreeNode, 1)
            call b:NERDTree.render()
            call newTreeNode.putCursorHere(1)
        endif
    catch /^NERDTree/
        call lighttree#echoWarning("Node Not Created.")
    endtry
endfunction

function! NERDTreeMoveNode()
    let curNode = g:NERDTreeFileNode.GetSelected()
    let newNodePath = input("Rename the current node\n" .
                          \ "==========================================================\n" .
                          \ "Enter the new path for the node:                          \n" .
                          \ "", curNode.path.str(), "file")

    if newNodePath ==# ''
        call lighttree#echo("Node Renaming Aborted.")
        return
    endif

    try
        let bufnum = bufnr("^".curNode.path.str()."$")

        call curNode.rename(newNodePath)
        call b:NERDTree.render()

        "if the node is open in a buffer, ask the user if they want to
        "close that buffer
        if bufnum != -1
            call s:replaceBuffer(bufnum, newNodePath)
        endif

        call curNode.putCursorHere(1)

        redraw
    catch /^NERDTree/
        call lighttree#echoWarning("Node Not Renamed.")
    endtry
endfunction

function! NERDTreeDeleteNode()
    let currentNode = g:NERDTreeFileNode.GetSelected()
    let confirmed = 0

    if currentNode.path.isDirectory && currentNode.getChildCount() > 0
        let choice =input("Delete the current node\n" .
                         \ "==========================================================\n" .
                         \ "STOP! Directory is not empty! To delete, type 'yes'\n" .
                         \ "" . currentNode.path.str() . ": ")
        let confirmed = choice ==# 'yes'
    else
        echo "Delete the current node\n" .
           \ "==========================================================\n".
           \ "Are you sure you wish to delete the node:\n" .
           \ "" . currentNode.path.str() . " (yN):"
        let choice = nr2char(getchar())
        let confirmed = choice ==# 'y'
    endif


    if confirmed
        try
            call currentNode.delete()
            call b:NERDTree.render()

            "if the node is open in a buffer, ask the user if they want to
            "close that buffer
            let bufnum = bufnr("^".currentNode.path.str()."$")
            if buflisted(bufnum)
                call s:deleteBuffer(bufnum)
            endif

            redraw
        catch /^NERDTree/
            call lighttree#echoWarning("Could not remove node")
        endtry
    else
        call lighttree#echo("delete aborted")
    endif

endfunction

function! NERDTreeListNode()
    let treenode = g:NERDTreeFileNode.GetSelected()
    if treenode != {}
        let metadata = split(system('ls -ld ' . shellescape(treenode.path.str())), '\n')
        call lighttree#echo(metadata[0])
    else
        call lighttree#echo("No information avaialable")
    endif
endfunction

function! NERDTreeListNodeWin32()
    let l:node = g:NERDTreeFileNode.GetSelected()

    if !empty(l:node)

        let l:save_shell = &shell
        set shell&

        if exists('+shellslash')
            let l:save_shellslash = &shellslash
            set noshellslash
        endif

        let l:command = 'DIR /Q '
                    \ . shellescape(l:node.path.str())
                    \ . ' | FINDSTR "^[012][0-9]/[0-3][0-9]/[12][0-9][0-9][0-9]"'

        let l:metadata = split(system(l:command), "\n")

        if v:shell_error == 0
            call lighttree#echo(l:metadata[0])
        else
            call lighttree#echoError('shell command failed')
        endif

        let &shell = l:save_shell

        if exists('l:save_shellslash')
            let &shellslash = l:save_shellslash
        endif

        return
    endif

    call lighttree#echo('node not recognized')
endfunction

function! NERDTreeCopyNode()
    let currentNode = g:NERDTreeFileNode.GetSelected()
    let newNodePath = input("Copy the current node\n" .
                          \ "==========================================================\n" .
                          \ "Enter the new path to copy the node to:                   \n" .
                          \ "", currentNode.path.str(), "file")

    if newNodePath != ""
        "strip trailing slash
        let newNodePath = substitute(newNodePath, '\/$', '', '')

        let confirmed = 1
        if currentNode.path.copyingWillOverwrite(newNodePath)
            call lighttree#echo("Warning: copying may overwrite files! Continue? (yN)")
            let choice = nr2char(getchar())
            let confirmed = choice ==# 'y'
        endif

        if confirmed
            try
                let newNode = currentNode.copy(newNodePath)
                if empty(newNode)
                    call b:NERDTree.root.refresh()
                    call b:NERDTree.render()
                else
                    call b:NERDTree.render()
                    call newNode.putCursorHere(0)
                endif
            catch /^NERDTree/
                call lighttree#echoWarning("Could not copy node")
            endtry
        endif
    else
        call lighttree#echo("Copy aborted.")
    endif
    redraw
endfunction

function! NERDTreeQuickLook()
    let treenode = g:NERDTreeFileNode.GetSelected()
    if treenode != {}
        call system("qlmanage -p 2>/dev/null '" . treenode.path.str() . "'")
    endif
endfunction

function! NERDTreeRevealInFinder()
    let treenode = g:NERDTreeFileNode.GetSelected()
    if treenode != {}
        call system("open -R '" . treenode.path.str() . "'")
    endif
endfunction

function! NERDTreeExecuteFile()
    let treenode = g:NERDTreeFileNode.GetSelected()
    if treenode != {}
        call system("open '" . treenode.path.str() . "'")
    endif
endfunction
" vim: set sw=4 sts=4 et fdm=marker:
