function! lighttree#buffer#restore_or_create(dir)
    if s:restore_buffer(a:dir)
        return
    else
        return s:create_buffer(a:dir)
    endif
endfunction

function! s:restore_buffer(dir) abort
    let path = g:NERDTreePath.New(fnamemodify(a:dir, ":p"))

    for i in range(1, bufnr("$"))
        unlet! nt
        let nt = getbufvar(i, "tree")
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

function! s:create_buffer(dir)
    let path = s:dir_for_string(a:dir)

    if empty(path)
        return
    endif

    if path == {}
        return
    endif

    exec "silent edit " . s:next_buffer_name()

    let b:tree = g:NERDTree.New(path)
    call b:tree.root.open()

    call s:configure_buffer()

    call s:setup_statusline()

    call lighttree#keymap#bind_all()

    call b:tree.ui.render()
endfunction

function! s:dir_for_string(str)
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

function! s:next_buffer_name()
    let name = g:LightTreeBufferNamePrefix . s:next_buffer_number()
    return name
endfunction

function! s:next_buffer_number()
    if !exists("s:current_buffer_number")
        let s:current_buffer_number = 1
    else
        let s:current_buffer_number += 1
    endif

    return s:current_buffer_number
endfunction

function! s:configure_buffer()
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

    setlocal filetype=lighttree
endfunction

function! s:setup_statusline()
    if g:LightTreeStatusline != -1
        let &l:statusline = g:LightTreeStatusline
    endif
endfunction
