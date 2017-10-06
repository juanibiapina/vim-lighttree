"This class is the parent of the TreeDirNode class and is the
"'Component' part of the composite design pattern between the treenode
"classes.
let s:TreeFileNode = {}
let g:NERDTreeFileNode = s:TreeFileNode

function! s:TreeFileNode.activate()
    call self.open()
endfunction

"initializes self.parent if it isnt already
function! s:TreeFileNode.cacheParent()
    if empty(self.parent)
        let parentPath = self.path.getParent()
        if parentPath.equals(self.path)
            throw "NERDTree.CannotCacheParentError: already at root"
        endif
        let self.parent = s:TreeFileNode.New(parentPath, self.getNerdtree())
    endif
endfunction

function! s:TreeFileNode.copy(dest)
    call self.path.copy(a:dest)
    let newPath = g:NERDTreePath.New(a:dest)
    let parent = self.getNerdtree().root.findNode(newPath.getParent())
    if !empty(parent)
        call parent.refresh()
        return parent.findNode(newPath)
    else
        return {}
    endif
endfunction

"Removes this node from the tree and calls the Delete method for its path obj
function! s:TreeFileNode.delete()
    call self.path.delete()
    call self.parent.removeChild(self)
endfunction

function! s:TreeFileNode.displayString()
    return self.path.displayString()
endfunction

"Compares this treenode to the input treenode and returns 1 if they are the
"same node.
"
"Use this method instead of ==  because sometimes when the treenodes contain
"many children, vim seg faults when doing ==
"
"Args:
"treenode: the other treenode to compare to
function! s:TreeFileNode.equals(treenode)
    return self.path.str() ==# a:treenode.path.str()
endfunction

"Returns self if this node.path.Equals the given path.
"Returns {} if not equal.
"
"Args:
"path: the path object to compare against
function! s:TreeFileNode.findNode(path)
    if a:path.equals(self.path)
        return self
    endif
    return {}
endfunction

"Finds the next sibling for this node in the indicated direction
"
"Args:
"direction: 0 if you want to find the previous sibling, 1 for the next sibling
"
"Return:
"a treenode object or {} if no sibling could be found
function! s:TreeFileNode.findSibling(direction)
    "if we have no parent then we can have no siblings
    if self.parent != {}

        "get the index of this node in its parents children
        let siblingIndx = self.parent.getChildIndex(self.path)

        if siblingIndx != -1
            "move a long to the next potential sibling node
            let siblingIndx = a:direction ==# 1 ? siblingIndx+1 : siblingIndx-1

            "keep moving along to the next sibling till we find one that is valid
            let numSiblings = self.parent.getChildCount()
            while siblingIndx >= 0 && siblingIndx < numSiblings

                "if the next node is not an ignored node (i.e. wont show up in the
                "view) then return it
                if self.parent.children[siblingIndx].path.ignore(self.getNerdtree()) ==# 0
                    return self.parent.children[siblingIndx]
                endif

                "go to next node
                let siblingIndx = a:direction ==# 1 ? siblingIndx+1 : siblingIndx-1
            endwhile
        endif
    endif

    return {}
endfunction

function! s:TreeFileNode.getNerdtree()
    return self._nerdtree
endfunction

"gets the treenode that the cursor is currently over
function! s:TreeFileNode.GetSelected()
    try
        let path = b:NERDTree.ui.getPath(line("."))
        if path ==# {}
            return {}
        endif
        return b:NERDTree.root.findNode(path)
    catch /^NERDTree/
        return {}
    endtry
endfunction

"returns 1 if this node should be visible according to the tree filters and
"hidden file filters (and their on/off status)
function! s:TreeFileNode.isVisible()
    return !self.path.ignore(self.getNerdtree())
endfunction

function! s:TreeFileNode.isRoot()
    if !exists("b:NERDTree")
        throw "NERDTree.NoTreeError: No tree exists for the current buffer"
    endif

    return self.equals(self.getNerdtree().root)
endfunction

"Returns a new TreeNode object with the given path and parent
"
"Args:
"path: file/dir that the node represents
"nerdtree: the tree the node belongs to
function! s:TreeFileNode.New(path, nerdtree)
    if a:path.isDirectory
        return g:NERDTreeDirNode.New(a:path, a:nerdtree)
    else
        let newTreeNode = copy(self)
        let newTreeNode.path = a:path
        let newTreeNode.parent = {}
        let newTreeNode._nerdtree = a:nerdtree
        return newTreeNode
    endif
endfunction

function! s:TreeFileNode.open()
    call self.path.edit()
endfunction

"Places the cursor on the line number this node is rendered on
"
"Args:
"isJump: 1 if this cursor movement should be counted as a jump by vim
function! s:TreeFileNode.putCursorHere(isJump)
    let ln = self.getNerdtree().ui.getLineNum(self)
    if ln != -1
        if a:isJump
            mark '
        endif
        call cursor(ln, col("."))
    endif
endfunction

function! s:TreeFileNode.refresh()
    call self.path.refresh(self.getNerdtree())
endfunction

function! s:TreeFileNode.refreshFlags()
    call self.path.refreshFlags(self.getNerdtree())
endfunction

"Calls the rename method for this nodes path obj
function! s:TreeFileNode.rename(newName)
    let newName = substitute(a:newName, '\(\\\|\/\)$', '', '')
    call self.path.rename(newName)
    call self.parent.removeChild(self)

    let parentPath = self.path.getParent()
    let newParent = self.getNerdtree().root.findNode(parentPath)

    if newParent != {}
        call newParent.createChild(self.path, 1)
        call newParent.refresh()
    endif
endfunction

"returns a string representation for this tree to be rendered in the view
function! s:TreeFileNode.renderToString()
    return self._renderToString(0, 0)
endfunction

"Args:
"depth: the current depth in the tree for this call
"drawText: 1 if we should actually draw the line for this node (if 0 then the
"child nodes are rendered only)
"for each depth in the tree
function! s:TreeFileNode._renderToString(depth, drawText)
    let output = ""
    if a:drawText ==# 1

        let treeParts = repeat('  ', a:depth - 1)

        if !self.path.isDirectory
            let treeParts = treeParts . '  '
        endif

        let line = treeParts . self.displayString()

        let output = output . line . "\n"
    endif

    "if the node is an open dir, draw its children
    if self.path.isDirectory ==# 1 && self.isOpen ==# 1

        let childNodesToDraw = self.getVisibleChildren()

        if len(childNodesToDraw) > 0
            for i in childNodesToDraw
                let output = output . i._renderToString(a:depth + 1, 1)
            endfor
        endif
    endif

    return output
endfunction
