let s:TreeDirNode = copy(g:NERDTreeFileNode)
let g:NERDTreeDirNode = s:TreeDirNode

" Class method that returns the highest cached ancestor of the current root.
function! s:TreeDirNode.AbsoluteTreeRoot()
    let currentNode = b:tree.root
    while currentNode.parent != {}
        let currentNode = currentNode.parent
    endwhile
    return currentNode
endfunction

unlet s:TreeDirNode.activate
function! s:TreeDirNode.activate()
    call self.toggleOpen()
    call self.getNerdtree().ui.render()
    call self.putCursorHere(0)
endfunction

" Adds the given treenode to the list of children for this node
"
" Args:
" -treenode: the node to add
" -inOrder: 1 if the new node should be inserted in sorted order
function! s:TreeDirNode.addChild(treenode, inOrder)
    call add(self.children, a:treenode)
    let a:treenode.parent = self

    if a:inOrder
        call self.sortChildren()
    endif
endfunction

" Mark this TreeDirNode as closed.
function! s:TreeDirNode.close()
    let self.isOpen = 0
endfunction

" Recursively close any directory nodes that are descendants of this node.
function! s:TreeDirNode.closeChildren()
    for l:child in self.children
        if l:child.path.isDirectory
            call l:child.close()
            call l:child.closeChildren()
        endif
    endfor
endfunction

" Instantiates a new child node for this node with the given path. The new
" nodes parent is set to this node.
"
" Args:
" path: a Path object that this node will represent/contain
" inOrder: 1 if the new node should be inserted in sorted order
"
" Returns:
" the newly created node
function! s:TreeDirNode.createChild(path, inOrder)
    let newTreeNode = g:NERDTreeFileNode.New(a:path, self.getNerdtree())
    call self.addChild(newTreeNode, a:inOrder)
    return newTreeNode
endfunction

" Assemble and return a string that can represent this TreeDirNode
function! s:TreeDirNode.displayString()
    if self.isOpen
        let l:symbol = g:LightTreeDirArrowCollapsible
    else
        let l:symbol = g:LightTreeDirArrowExpandable
    endif

    let l:label = self.path.displayString()

    return l:symbol . ' ' . l:label
endfunction

" Will find one of the children (recursively) that has the given path
"
" Args:
" path: a path object
unlet s:TreeDirNode.findNode
function! s:TreeDirNode.findNode(path)
    if a:path.equals(self.path)
        return self
    endif
    if stridx(a:path.str(), self.path.str(), 0) ==# -1
        return {}
    endif

    if self.path.isDirectory
        for i in self.children
            let retVal = i.findNode(a:path)
            if retVal != {}
                return retVal
            endif
        endfor
    endif
    return {}
endfunction

" Returns the number of children this node has
function! s:TreeDirNode.getChildCount()
    return len(self.children)
endfunction

" Returns child node of this node that has the given path or {} if no such node
" exists.
"
" This function doesnt not recurse into child dir nodes
"
" Args:
" path: a path object
function! s:TreeDirNode.getChild(path)
    if stridx(a:path.str(), self.path.str(), 0) ==# -1
        return {}
    endif

    let index = self.getChildIndex(a:path)
    if index ==# -1
        return {}
    else
        return self.children[index]
    endif

endfunction

" returns the child at the given index
"
" Args:
" indx: the index to get the child from
" visible: 1 if only the visible children array should be used, 0 if all the
" children should be searched.
function! s:TreeDirNode.getChildByIndex(indx, visible)
    let array_to_search = a:visible? self.getVisibleChildren() : self.children
    if a:indx > len(array_to_search)
        throw "NERDTree.InvalidArgumentsError: Index is out of bounds."
    endif
    return array_to_search[a:indx]
endfunction

" Returns the index of the child node of this node that has the given path or
" -1 if no such node exists.
"
" This function doesnt not recurse into child dir nodes
"
" Args:
" path: a path object
function! s:TreeDirNode.getChildIndex(path)
    if stridx(a:path.str(), self.path.str(), 0) ==# -1
        return -1
    endif

    "do a binary search for the child
    let a = 0
    let z = self.getChildCount()
    while a < z
        let mid = (a+z)/2
        let diff = a:path.compareTo(self.children[mid].path)

        if diff ==# -1
            let z = mid
        elseif diff ==# 1
            let a = mid+1
        else
            return mid
        endif
    endwhile
    return -1
endfunction

" Return a list of strings naming the descendants of the directory in this
" TreeDirNode object that match the specified glob pattern.
"
" Args:
" pattern: (string) the glob pattern to apply
" all: (0 or 1) if 1, include "." and ".." if they match "pattern"; if 0,
"      always exclude them
"
" Note: If the pathnames in the result list are below the working directory,
" they are returned as pathnames relative to that directory. This is because
" this function, internally, attempts to obey 'wildignore' rules that use
" relative paths.
function! s:TreeDirNode._glob(pattern, all)

    " Construct a path specification such that "globpath()" will return
    " relative pathnames, if possible.
    if self.path.str() == getcwd()
        let l:pathSpec = ','
    else
        let l:pathSpec = fnamemodify(self.path.str({'format': 'Glob'}), ':.')

        " On Windows, the drive letter may be removed by "fnamemodify()".
        if lighttree#os#is_windows() && l:pathSpec[0] == g:NERDTreePath.Slash()
            let l:pathSpec = self.path.drive . l:pathSpec
        endif
    endif

    let l:globList = []

    " See ":h version7.txt" and ":h version8.txt" for details on the
    " development of the "glob()" and "globpath()" functions.
    if v:version > 704 || (v:version == 704 && has('patch654'))
        let l:globList = globpath(l:pathSpec, a:pattern, !g:LightTreeRespectWildIgnore, 1, 0)
    elseif v:version == 704 && has('patch279')
        let l:globList = globpath(l:pathSpec, a:pattern, !g:LightTreeRespectWildIgnore, 1)
    elseif v:version > 702 || (v:version == 702 && has('patch051'))
        let l:globString = globpath(l:pathSpec, a:pattern, !g:LightTreeRespectWildIgnore)
        let l:globList = split(l:globString, "\n")
    else
        let l:globString = globpath(l:pathSpec, a:pattern)
        let l:globList = split(l:globString, "\n")
    endif

    " If "a:all" is false, filter "." and ".." from the output.
    if !a:all
        let l:toRemove = []

        for l:file in l:globList
            let l:tail = fnamemodify(l:file, ':t')

            " Double the modifier if only a separator was stripped.
            if l:tail == ''
                let l:tail = fnamemodify(l:file, ':t:t')
            endif

            if l:tail == '.' || l:tail == '..'
                call add(l:toRemove, l:file)
                if len(l:toRemove) == 2
                    break
                endif
            endif
        endfor

        for l:file in l:toRemove
            call remove(l:globList, index(l:globList, l:file))
        endfor
    endif

    return l:globList
endfunction

" Returns the number of visible children this node has
function! s:TreeDirNode.getVisibleChildCount()
    return len(self.getVisibleChildren())
endfunction

" Returns a list of children to display for this node, in the correct order
"
" Return:
" an array of treenodes
function! s:TreeDirNode.getVisibleChildren()
    let toReturn = []
    for i in self.children
        if i.path.ignore(self.getNerdtree()) ==# 0
            call add(toReturn, i)
        endif
    endfor
    return toReturn
endfunction

" returns 1 if this node has any childre, 0 otherwise..
function! s:TreeDirNode.hasVisibleChildren()
    return self.getVisibleChildCount() != 0
endfunction

" Removes all childen from this node and re-reads them
"
" Args:
" silent: 1 if the function should not echo any "please wait" messages for
" large directories
"
" Return: the number of child nodes read
function! s:TreeDirNode._initChildren(silent)
    "remove all the current child nodes
    let self.children = []

    let files = self._glob('*', 1) + self._glob('.*', 0)

    if !a:silent && len(files) > g:LightTreeNotificationThreshold
        call lighttree#echo("Please wait, caching a large dir ...")
    endif

    let invalidFilesFound = 0
    for i in files
        try
            let path = g:NERDTreePath.New(i)
            call self.createChild(path, 0)
        catch /^NERDTree.\(InvalidArguments\|InvalidFiletype\)Error/
            let invalidFilesFound += 1
        endtry
    endfor

    call self.sortChildren()

    if !a:silent && len(files) > g:LightTreeNotificationThreshold
        call lighttree#echo("Please wait, caching a large dir ... DONE (". self.getChildCount() ." nodes cached).")
    endif

    if invalidFilesFound
        call lighttree#echoWarning(invalidFilesFound . " file(s) could not be loaded into the NERD tree")
    endif
    return self.getChildCount()
endfunction

" Return a new TreeDirNode object with the given path and parent.
"
" Args:
" path: dir that the node represents
" nerdtree: the tree the node belongs to
function! s:TreeDirNode.New(path, nerdtree)
    if a:path.isDirectory != 1
        throw "NERDTree.InvalidArgumentsError: A TreeDirNode object must be instantiated with a directory Path object."
    endif

    let newTreeNode = copy(self)
    let newTreeNode.path = a:path

    let newTreeNode.isOpen = 0
    let newTreeNode.children = []

    let newTreeNode.parent = {}
    let newTreeNode._nerdtree = a:nerdtree

    return newTreeNode
endfunction

" Open this directory node in the current tree. Return the number of new
" cached nodes.
function! s:TreeDirNode.open()
    let self.isOpen = 1

    let l:numChildrenCached = 0
    if empty(self.children)
        let l:numChildrenCached = self._initChildren(0)
    endif

    return l:numChildrenCached
endfunction

" recursive open the dir if it has only one directory child.
"
" return the level of opened directories.
function! s:TreeDirNode.openAlong()
    let level = 0

    let node = self
    while node.path.isDirectory
        call node.open()
        let level += 1
        if node.getVisibleChildCount() == 1
            let node = node.getChildByIndex(0, 1)
        else
            break
        endif
    endwhile
    return level
endfunction

" Open this directory node and any descendant directory nodes whose pathnames
" are not ignored.
function! s:TreeDirNode.openRecursively()
    silent call self.open()

    for l:child in self.children
        if l:child.path.isDirectory && !l:child.path.ignore(l:child.getNerdtree())
            call l:child.openRecursively()
        endif
    endfor
endfunction

function! s:TreeDirNode.refresh()
    call self.path.refresh(self.getNerdtree())

    "if this node was ever opened, refresh its children
    if self.isOpen || !empty(self.children)
        let files = self._glob('*', 1) + self._glob('.*', 0)
        let newChildNodes = []
        let invalidFilesFound = 0
        for i in files
            try
                "create a new path and see if it exists in this nodes children
                let path = g:NERDTreePath.New(i)
                let newNode = self.getChild(path)
                if newNode != {}
                    call newNode.refresh()
                    call add(newChildNodes, newNode)

                "the node doesnt exist so create it
                else
                    let newNode = g:NERDTreeFileNode.New(path, self.getNerdtree())
                    let newNode.parent = self
                    call add(newChildNodes, newNode)
                endif
            catch /^NERDTree.\(InvalidArguments\|InvalidFiletype\)Error/
                let invalidFilesFound = 1
            endtry
        endfor

        "swap this nodes children out for the children we just read/refreshed
        let self.children = newChildNodes
        call self.sortChildren()

        if invalidFilesFound
            call lighttree#echoWarning("some files could not be loaded into the NERD tree")
        endif
    endif
endfunction

unlet s:TreeDirNode.refreshFlags
function! s:TreeDirNode.refreshFlags()
    call self.path.refreshFlags(self.getNerdtree())
    for i in self.children
        call i.refreshFlags()
    endfor
endfunction

function! s:TreeDirNode.refreshDirFlags()
    call self.path.refreshFlags(self.getNerdtree())
endfunction

" reveal the given path, i.e. cache and open all treenodes needed to display it
" in the UI
" Returns the revealed node
function! s:TreeDirNode.reveal(path)
    if !a:path.isUnder(self.path)
        throw "NERDTree.InvalidArgumentsError: " . a:path.str() . " should be under " . self.path.str()
    endif

    call self.open()

    if self.path.equals(a:path.getParent())
        return self.findNode(a:path)
    endif

    let p = a:path
    while !p.getParent().equals(self.path)
        let p = p.getParent()
    endwhile

    let n = self.findNode(p)
    return n.reveal(a:path)
endfunction

" Remove the given treenode from "self.children".
" Throws "NERDTree.ChildNotFoundError" if the node is not found.
"
" Args:
" treenode: the node object to remove
function! s:TreeDirNode.removeChild(treenode)
    for i in range(0, self.getChildCount()-1)
        if self.children[i].equals(a:treenode)
            call remove(self.children, i)
            return
        endif
    endfor

    throw "NERDTree.ChildNotFoundError: child node was not found"
endfunction

function! s:TreeDirNode.sortChildren()
    let CompareFunc = function("s:compareNodesBySortKey")
    call sort(self.children, CompareFunc)
endfunction

function! s:compareNodesBySortKey(n1, n2)
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


" Opens this directory if it is closed and vice versa
function! s:TreeDirNode.toggleOpen()
    if self.isOpen ==# 1
        call self.close()
    else
        if g:LightTreeCascadeOpenSingleChildDir == 0
            call self.open()
        else
            call self.openAlong()
        endif
    endif
endfunction

" Replaces the child of this with the given node (where the child node's full
" path matches a:newNode's fullpath). The search for the matching node is
" non-recursive
"
" Arg:
" newNode: the node to graft into the tree
function! s:TreeDirNode.transplantChild(newNode)
    for i in range(0, self.getChildCount()-1)
        if self.children[i].equals(a:newNode)
            let self.children[i] = a:newNode
            let a:newNode.parent = self
            break
        endif
    endfor
endfunction
