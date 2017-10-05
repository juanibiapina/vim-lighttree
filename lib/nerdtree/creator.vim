let g:NERDTreeCreator = {}

function! g:NERDTreeCreator.createWindowTree(dir)
    let path = self._pathForString(a:dir)

    if empty(path)
        return
    endif

    if path == {}
        return
    endif

    exec "silent edit " . self._nextBufferName()

    let b:NERDTree = g:NERDTree.New(path)
    call b:NERDTree.root.open()

    call self._configureBuffer()

    call b:NERDTree.render()
endfunction

function! g:NERDTreeCreator._nextBufferName()
    let name = g:LightTreeBufferNamePrefix . self._nextBufferNumber()
    return name
endfunction

function! g:NERDTreeCreator._nextBufferNumber()
    if !exists("g:NERDTreeCreator._NextBufNum")
        let g:NERDTreeCreator._NextBufNum = 1
    else
        let g:NERDTreeCreator._NextBufNum += 1
    endif

    return g:NERDTreeCreator._NextBufNum
endfunction

"find a directory for the given string
function! g:NERDTreeCreator._pathForString(str)
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

function! g:NERDTreeCreator._configureBuffer()
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

    call lighttree#keymap#bind_all()

    setlocal filetype=lighttree
endfunction

function! g:NERDTreeCreator._setupStatusline()
    if g:LightTreeStatusline != -1
        let &l:statusline = g:LightTreeStatusline
    endif
endfunction

function! g:NERDTreeCreator.restoreBuffer(dir) abort
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

function! g:NERDTreeCreator.RestoreOrCreateBuffer(dir)
    if g:NERDTreeCreator.restoreBuffer(a:dir)
        return
    else
        return g:NERDTreeCreator.createWindowTree(a:dir)
    endif
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
