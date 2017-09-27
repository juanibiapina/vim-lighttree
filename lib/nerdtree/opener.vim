let s:Opener = {}
let g:NERDTreeOpener = s:Opener

" Args:
"
" a:path: The path object that is to be opened.
function! s:Opener.New(path)
    let newObj = copy(self)

    let newObj._path = a:path

    let newObj._nerdtree = b:NERDTree

    return newObj
endfunction

function! s:Opener.open(target)
    if self._path.isDirectory
        call self._openDirectory(a:target)
    else
        call self._openFile()
    endif
endfunction

function! s:Opener._openFile()
    call self._path.edit()
endfunction

function! s:Opener._openDirectory(node)
    if self._nerdtree.isWinTree()
        call g:NERDTreeCreator.CreateWindowTree(a:node.path.str())
    else
        call b:NERDTree.changeRoot(a:node)
    endif
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
