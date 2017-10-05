let s:NERDTree = {}
let g:NERDTree = s:NERDTree

function! s:NERDTree.changeRoot(node)
    if a:node.path.isDirectory
        let self.root = a:node
    else
        call a:node.cacheParent()
        let self.root = a:node.parent
    endif

    call self.root.open()

    call self.render()
    call self.root.putCursorHere(0)
endfunction

function! s:NERDTree.New(path)
    let newObj = copy(self)
    let newObj.ui = g:NERDTreeUI.New(newObj)
    let newObj.root = g:NERDTreeDirNode.New(a:path, newObj)
    return newObj
endfunction

"A convenience function - since this is called often
function! s:NERDTree.render()
    call self.ui.render()
endfunction
