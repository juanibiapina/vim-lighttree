" ============================================================================
" CLASS: Opener
"
" The Opener class defines an API for "opening" operations.
" ============================================================================


let s:Opener = {}
let g:NERDTreeOpener = s:Opener

" FUNCTION: Opener.New(path, opts) {{{1
" Args:
"
" a:path: The path object that is to be opened.
function! s:Opener.New(path)
    let newObj = copy(self)

    let newObj._path = a:path

    let newObj._nerdtree = b:NERDTree

    return newObj
endfunction

" FUNCTION: Opener.open(target) {{{1
function! s:Opener.open(target)
    if self._path.isDirectory
        call self._openDirectory(a:target)
    else
        call self._openFile()
    endif
endfunction

" FUNCTION: Opener._openFile() {{{1
function! s:Opener._openFile()
    call self._path.edit()
endfunction

" FUNCTION: Opener._openDirectory(node) {{{1
function! s:Opener._openDirectory(node)
    if self._nerdtree.isWinTree()
        call g:NERDTreeCreator.CreateWindowTree(a:node.path.str())
    else
        call b:NERDTree.changeRoot(a:node)
    endif
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
