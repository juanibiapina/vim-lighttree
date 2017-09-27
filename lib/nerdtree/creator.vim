"Creates tab/window nerdtree windows. Sets up all the window and
"buffer options and key mappings etc.
let s:Creator = {}
let g:NERDTreeCreator = s:Creator

function! s:Creator._bindMappings()
    "make <cr> do the same as the activate node mapping
    nnoremap <silent> <buffer> <cr> :call nerdtree#ui_glue#invokeKeyMap(g:NERDTreeMapActivateNode)<cr>

    call g:NERDTreeKeyMap.BindAll()
endfunction

function! s:Creator._broadcastInitEvent()
    silent doautocmd User LightTreeInit
endfunction

function! s:Creator.BufNamePrefix()
    return 'NERD_tree_'
endfunction

function! s:Creator.CreateTabTree(name)
    let creator = s:Creator.New()
    call creator.createTabTree(a:name)
endfunction

function! s:Creator.createTabTree(name)
    let path = self._pathForString(a:name)

    if empty(path)
        return
    endif

    if path == {}
        return
    endif

    if g:NERDTree.ExistsForTab()
        if g:NERDTree.IsOpen()
            call g:NERDTree.Close()
        endif

        call self._removeTreeBufForTab()
    endif

    call self._createTreeWin()
    call self._createNERDTree(path, "tab")
    call b:NERDTree.render()
    call b:NERDTree.root.putCursorHere(0, 0)

    call self._broadcastInitEvent()
endfunction

function! s:Creator.CreateWindowTree(dir)
    let creator = s:Creator.New()
    call creator.createWindowTree(a:dir)
endfunction

function! s:Creator.createWindowTree(dir)
    let path = self._pathForString(a:dir)

    if empty(path)
        return
    endif

    if path == {}
        return
    endif

    "we want the directory buffer to disappear when we do the :edit below
    setlocal bufhidden=wipe

    let previousBuf = expand("#")

    "we need a unique name for each window tree buffer to ensure they are
    "all independent
    exec g:NERDTreeCreatePrefix . " edit " . self._nextBufferName()

    call self._createNERDTree(path, "window")
    let b:NERDTree._previousBuf = bufnr(previousBuf)
    call self._setCommonBufOptions()

    call b:NERDTree.render()

    call self._broadcastInitEvent()
endfunction

function! s:Creator._createNERDTree(path, type)
    let b:NERDTree = g:NERDTree.New(a:path, a:type)

    call b:NERDTree.root.open()
endfunction

"Inits the NERD tree window. ie. opens it, sizes it, sets all the local
"options etc
function! s:Creator._createTreeWin()
    "create the nerd tree window
    let splitLocation = g:NERDTreeWinPos ==# "left" ? "topleft " : "botright "
    let splitSize = g:NERDTreeWinSize

    if !exists('t:NERDTreeBufName')
        let t:NERDTreeBufName = self._nextBufferName()
        silent! exec splitLocation . 'vertical ' . splitSize . ' new'
        silent! exec "edit " . t:NERDTreeBufName
    else
        silent! exec splitLocation . 'vertical ' . splitSize . ' split'
        silent! exec "buffer " . t:NERDTreeBufName
    endif

    setlocal winfixwidth
    call self._setCommonBufOptions()
endfunction

function! s:Creator._isBufHidden(nr)
    redir => bufs
    silent ls!
    redir END

    return bufs =~ a:nr . '..h'
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
        call nerdtree#echo("No directory found for: " . a:str)
        return {}
    endtry

    if !path.isDirectory
        let path = path.getParent()
    endif

    return path
endfunction

" Function: s:Creator._removeTreeBufForTab()   {{{1
function! s:Creator._removeTreeBufForTab()
    let buf = bufnr(t:NERDTreeBufName)

    "if &hidden is not set then it will already be gone
    if buf != -1

        "nerdtree buf may be mirrored/displayed elsewhere
        if self._isBufHidden(buf)
            exec "bwipeout " . buf
        endif

    endif

    unlet t:NERDTreeBufName
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
    if g:NERDTreeShowLineNumbers
        setlocal nu
    else
        setlocal nonu
        if v:version >= 703
            setlocal nornu
        endif
    endif

    iabc <buffer>

    if g:NERDTreeHighlightCursorline
        setlocal cursorline
    endif

    call self._setupStatusline()
    call self._bindMappings()
    setlocal filetype=nerdtree
endfunction

function! s:Creator._setupStatusline()
    if g:NERDTreeStatusline != -1
        let &l:statusline = g:NERDTreeStatusline
    endif
endfunction

function! s:Creator._tabpagevar(tabnr, var)
    let currentTab = tabpagenr()
    let old_ei = &ei
    set ei=all

    exec "tabnext " . a:tabnr
    let v = -1
    if exists('t:' . a:var)
        exec 'let v = t:' . a:var
    endif
    exec "tabnext " . currentTab

    let &ei = old_ei

    return v
endfunction

function! s:Creator.ToggleTabTree(dir)
    let creator = s:Creator.New()
    call creator.toggleTabTree(a:dir)
endfunction

"Toggles the NERD tree. I.e the NERD tree is open, it is closed, if it is
"closed it is restored or initialized (if it doesnt exist)
"
"Args:
"dir: the full path for the root node (is only used if the NERD tree is being
"initialized.
function! s:Creator.toggleTabTree(dir)
    if g:NERDTree.ExistsForTab()
        if !g:NERDTree.IsOpen()
            call self._createTreeWin()
            if !&hidden
                call b:NERDTree.render()
            endif
            call b:NERDTree.ui.restoreScreenState()
        else
            call g:NERDTree.Close()
        endif
    else
        call self.createTabTree(a:dir)
    endif
endfunction

function! s:Creator.RestoreBuffer(dir)
    let creator = s:Creator.New()
    return creator.restoreBuffer(a:dir)
endfunction

function! s:Creator.restoreBuffer(dir) abort
    let path = g:NERDTreePath.New(fnamemodify(a:dir, ":p"))

    for i in range(1, bufnr("$"))
        unlet! nt
        let nt = getbufvar(i, "NERDTree")
        if empty(nt)
            continue
        endif

        if nt.isWinTree() && nt.root.path.equals(path)
            call nt.setPreviousBuf(bufnr("#"))
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

" Function: s:Creator._uniq(list)   {{{1
" returns a:list without duplicates
function! s:Creator._uniq(list)
  let uniqlist = []
  for elem in a:list
    if index(uniqlist, elem) ==# -1
      let uniqlist += [elem]
    endif
  endfor
  return uniqlist
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
