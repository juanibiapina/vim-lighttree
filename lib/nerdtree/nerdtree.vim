let s:NERDTree = {}
let g:NERDTree = s:NERDTree

function! s:NERDTree.AddPathFilter(callback)
    call add(s:NERDTree.PathFilters(), a:callback)
endfunction

function! s:NERDTree.changeRoot(node)
    if a:node.path.isDirectory
        let self.root = a:node
    else
        call a:node.cacheParent()
        let self.root = a:node.parent
    endif

    call self.root.open()

    call self.render()
    call self.root.putCursorHere(0, 0)

    silent doautocmd User LightTreeNewRoot
endfunction

function! s:NERDTree.getRoot()
    return self.root
endfunction

function! s:NERDTree.New(path)
    let newObj = copy(self)
    let newObj.ui = g:NERDTreeUI.New(newObj)
    let newObj.root = g:NERDTreeDirNode.New(a:path, newObj)
    return newObj
endfunction

function! s:NERDTree.PathFilters()
    if !exists('s:NERDTree._PathFilters')
        let s:NERDTree._PathFilters = []
    endif
    return s:NERDTree._PathFilters
endfunction

"A convenience function - since this is called often
function! s:NERDTree.render()
    call self.ui.render()
endfunction
