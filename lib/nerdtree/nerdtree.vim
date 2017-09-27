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

"Closes the tab tree window for this tab
function! s:NERDTree.Close()
    if !s:NERDTree.IsOpen()
        return
    endif

    if winnr("$") != 1
        if winnr() == s:NERDTree.GetWinNum()
            call nerdtree#exec("wincmd p")
            let bufnr = bufnr("")
            call nerdtree#exec("wincmd p")
        else
            let bufnr = bufnr("")
        endif

        call nerdtree#exec(s:NERDTree.GetWinNum() . " wincmd w")
        close
        call nerdtree#exec(bufwinnr(bufnr) . " wincmd w")
    else
        close
    endif
endfunction

"Places the cursor in the nerd tree window
function! s:NERDTree.CursorToTreeWin()
    call g:NERDTree.MustBeOpen()
    call nerdtree#exec(g:NERDTree.GetWinNum() . "wincmd w")
endfunction

" Returns 1 if a nerd tree root exists in the current tab
function! s:NERDTree.ExistsForTab()
    if !exists("t:NERDTreeBufName")
        return
    end

    "check b:NERDTree is still there and hasn't been e.g. :bdeleted
    return !empty(getbufvar(bufnr(t:NERDTreeBufName), 'NERDTree'))
endfunction

function! s:NERDTree.getRoot()
    return self.root
endfunction

"gets the nerd tree window number for this tab
function! s:NERDTree.GetWinNum()
    if exists("t:NERDTreeBufName")
        return bufwinnr(t:NERDTreeBufName)
    endif

    return -1
endfunction

function! s:NERDTree.IsOpen()
    return s:NERDTree.GetWinNum() != -1
endfunction

function! s:NERDTree.MustBeOpen()
    if !s:NERDTree.IsOpen()
        throw "NERDTree.TreeNotOpen"
    endif
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
