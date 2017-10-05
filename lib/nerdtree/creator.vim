let s:Creator = {}
let g:NERDTreeCreator = s:Creator

function! s:Creator._bindMappings()
    "make <cr> do the same as the activate node mapping
    nnoremap <silent> <buffer> <cr> :call lighttree#keymap#invoke(g:LightTreeMapActivateNode)<cr>

    call lighttree#keymap#bind_all()
endfunction

function! s:Creator._broadcastInitEvent()
    silent doautocmd User LightTreeInit
endfunction

function! s:Creator.BufNamePrefix()
    return 'NERD_tree_'
endfunction

function! s:Creator.createWindowTree(dir)
    let path = self._pathForString(a:dir)

    if empty(path)
        return
    endif

    if path == {}
        return
    endif

    "we need a unique name for each window tree buffer to ensure they are
    "all independent
    exec "silent edit " . self._nextBufferName()

    call self._createNERDTree(path)
    call self._setCommonBufOptions()

    call b:NERDTree.render()

    call self._broadcastInitEvent()
endfunction

function! s:Creator._createNERDTree(path)
    let b:NERDTree = g:NERDTree.New(a:path)

    call b:NERDTree.root.open()
endfunction

function! s:Creator.New()
    let newCreator = copy(self)
    return newCreator
endfunction

" returns the buffer name for the next nerd tree
function! s:Creator._nextBufferName()
    let name = s:Creator.BufNamePrefix() . self._nextBufferNumber()
    return name
endfunction

" the number to add to the nerd tree buffer name to make the buf name unique
function! s:Creator._nextBufferNumber()
    if !exists("s:Creator._NextBufNum")
        let s:Creator._NextBufNum = 1
    else
        let s:Creator._NextBufNum += 1
    endif

    return s:Creator._NextBufNum
endfunction

"find a directory for the given string
function! s:Creator._pathForString(str)
    let path = {}

    let dir = a:str ==# '' ? getcwd() : a:str

    "hack to get an absolute path if a relative path is given
    if dir =~# '^\.'
        let dir = getcwd() . g:NERDTreePath.Slash() . dir
    endif
    let dir = g:NERDTreePath.Resolve(dir)

    try
        let path = g:NERDTreePath.New(dir)
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("No directory found for: " . a:str)
        return {}
    endtry

    if !path.isDirectory
        let path = path.getParent()
    endif

    return path
endfunction

function! s:Creator._setCommonBufOptions()
    "throwaway buffer options
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal foldmethod=manual
    setlocal nofoldenable
    setlocal nobuflisted
    setlocal nospell
    if g:LightTreeShowLineNumbers
        setlocal nu
    else
        setlocal nonu
        if v:version >= 703
            setlocal nornu
        endif
    endif

    iabc <buffer>

    if g:LightTreeHighlightCursorline
        setlocal cursorline
    endif

    call self._setupStatusline()
    call self._bindMappings()
    setlocal filetype=lighttree
endfunction

function! s:Creator._setupStatusline()
    if g:LightTreeStatusline != -1
        let &l:statusline = g:LightTreeStatusline
    endif
endfunction

function! s:Creator.restoreBuffer(dir) abort
    let path = g:NERDTreePath.New(fnamemodify(a:dir, ":p"))

    for i in range(1, bufnr("$"))
        unlet! nt
        let nt = getbufvar(i, "NERDTree")
        if empty(nt)
            continue
        endif

        if nt.root.path.equals(path)
            exec "buffer " . i
            return 1
        endif
    endfor

    return 0
endfunction

function! s:Creator.RestoreOrCreateBuffer(dir)
    let creator = s:Creator.New()

    if creator.restoreBuffer(a:dir)
        return
    else
        return creator.createWindowTree(a:dir)
    endif
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
