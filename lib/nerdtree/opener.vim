" ============================================================================
" CLASS: Opener
"
" The Opener class defines an API for "opening" operations.
" ============================================================================


let s:Opener = {}
let g:NERDTreeOpener = s:Opener

" FUNCTION: s:Opener._bufInWindows(bnum) {{{1
" [[STOLEN FROM VTREEEXPLORER.VIM]]
" Determine the number of windows open to this buffer number.
" Care of Yegappan Lakshman.  Thanks!
"
" Args:
" bnum: the subject buffers buffer number
function! s:Opener._bufInWindows(bnum)
    let cnt = 0
    let winnum = 1
    while 1
        let bufnum = winbufnr(winnum)
        if bufnum < 0
            break
        endif
        if bufnum ==# a:bnum
            let cnt = cnt + 1
        endif
        let winnum = winnum + 1
    endwhile

    return cnt
endfunction

function! s:Opener._checkToCloseTree()
    if self._keepopen
        return
    endif
endfunction

" FUNCTION: s:Opener._firstUsableWindow() {{{1
" find the window number of the first normal window
function! s:Opener._firstUsableWindow()
    let i = 1
    while i <= winnr("$")
        let bnum = winbufnr(i)
        if bnum != -1 && getbufvar(bnum, '&buftype') ==# ''
                    \ && !getwinvar(i, '&previewwindow')
                    \ && (!getbufvar(bnum, '&modified') || &hidden)
            return i
        endif

        let i += 1
    endwhile
    return -1
endfunction

" FUNCTION: Opener._gotoTargetWin() {{{1
function! s:Opener._gotoTargetWin()
    if b:NERDTree.isWinTree()
        if self._where == 'v'
            vsplit
        elseif self._where == 'h'
            split
        endif
    else
        if self._where == 'v'
            call self._newVSplit()
        elseif self._where == 'h'
            call self._newSplit()
        elseif self._where == 'p'
            call self._previousWindow()
        endif

        call self._checkToCloseTree(0)
    endif
endfunction

" FUNCTION: s:Opener._isWindowUsable(winnumber) {{{1
" Returns 0 if opening a file from the tree in the given window requires it to
" be split, 1 otherwise
"
" Args:
" winnumber: the number of the window in question
function! s:Opener._isWindowUsable(winnumber)
    "gotta split if theres only one window (i.e. the NERD tree)
    if winnr("$") ==# 1
        return 0
    endif

    let oldwinnr = winnr()
    call nerdtree#exec(a:winnumber . "wincmd p")
    let specialWindow = getbufvar("%", '&buftype') != '' || getwinvar('%', '&previewwindow')
    let modified = &modified
    call nerdtree#exec(oldwinnr . "wincmd p")

    "if its a special window e.g. quickfix or another explorer plugin then we
    "have to split
    if specialWindow
        return 0
    endif

    if &hidden
        return 1
    endif

    return !modified || self._bufInWindows(winbufnr(a:winnumber)) >= 2
endfunction

" FUNCTION: Opener.New(path, opts) {{{1
" Args:
"
" a:path: The path object that is to be opened.
"
" a:opts:
"
" A dictionary containing the following keys (all optional):
"   'where': Specifies whether the node should be opened in new split or in
"            the previous window. Can be either 'v' or 'h'
"   'keepopen': dont close the tree window
"   'stay': open the file, but keep the cursor in the tree win
function! s:Opener.New(path, opts)
    let newObj = copy(self)

    let newObj._path = a:path
    let newObj._stay = nerdtree#has_opt(a:opts, 'stay')

    let newObj._keepopen = nerdtree#has_opt(a:opts, 'keepopen')
    let newObj._where = has_key(a:opts, 'where') ? a:opts['where'] : ''
    let newObj._nerdtree = b:NERDTree
    call newObj._saveCursorPos()

    return newObj
endfunction

" FUNCTION: Opener._newSplit() {{{1
function! s:Opener._newSplit()
    " Save the user's settings for splitbelow and splitright
    let savesplitbelow=&splitbelow
    let savesplitright=&splitright

    " 'there' will be set to a command to move from the split window
    " back to the explorer window
    "
    " 'back' will be set to a command to move from the explorer window
    " back to the newly split window
    "
    " 'right' and 'below' will be set to the settings needed for
    " splitbelow and splitright IF the explorer is the only window.
    "
    let there= g:NERDTreeWinPos ==# "left" ? "wincmd h" : "wincmd l"
    let back = g:NERDTreeWinPos ==# "left" ? "wincmd l" : "wincmd h"
    let right= g:NERDTreeWinPos ==# "left"
    let below=0

    " Attempt to go to adjacent window
    call nerdtree#exec(back)

    let onlyOneWin = (winnr("$") ==# 1)

    " If no adjacent window, set splitright and splitbelow appropriately
    if onlyOneWin
        let &splitright=right
        let &splitbelow=below
    else
        " found adjacent window - invert split direction
        let &splitright=!right
        let &splitbelow=!below
    endif

    let splitMode = onlyOneWin ? "vertical" : ""

    " Open the new window
    try
        exec(splitMode." sp ")
    catch /^Vim\%((\a\+)\)\=:E37/
        call g:NERDTree.CursorToTreeWin()
        throw "NERDTree.FileAlreadyOpenAndModifiedError: ". self._path.str() ." is already open and modified."
    catch /^Vim\%((\a\+)\)\=:/
        "do nothing
    endtry

    "resize the tree window if no other window was open before
    if onlyOneWin
        let size = exists("b:NERDTreeOldWindowSize") ? b:NERDTreeOldWindowSize : g:NERDTreeWinSize
        call nerdtree#exec(there)
        exec("silent ". splitMode ." resize ". size)
        call nerdtree#exec('wincmd p')
    endif

    " Restore splitmode settings
    let &splitbelow=savesplitbelow
    let &splitright=savesplitright
endfunction

" FUNCTION: Opener._newVSplit() {{{1
function! s:Opener._newVSplit()
    let l:winwidth = winwidth('.')

    if winnr('$') == 1
        let l:winwidth = g:NERDTreeWinSize
    endif

    call nerdtree#exec('wincmd p')
    vnew

    let l:currentWindowNumber = winnr()

    " Restore the NERDTree to its original width.
    call g:NERDTree.CursorToTreeWin()
    execute 'silent vertical resize ' . l:winwidth

    call nerdtree#exec(l:currentWindowNumber . 'wincmd w')
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
    call self._gotoTargetWin()
    call self._path.edit()
    if self._stay
        call self._restoreCursorPos()
    endif
endfunction

" FUNCTION: Opener._openDirectory(node) {{{1
function! s:Opener._openDirectory(node)
    if self._nerdtree.isWinTree()
        call self._gotoTargetWin()
        call g:NERDTreeCreator.CreateWindowTree(a:node.path.str())
    else
        call self._gotoTargetWin()
        if empty(self._where)
            call b:NERDTree.changeRoot(a:node)
        else
            call g:NERDTreeCreator.CreateWindowTree(a:node.path.str())
        endif
    endif

    if self._stay
        call self._restoreCursorPos()
    endif
endfunction

" FUNCTION: Opener._previousWindow() {{{1
function! s:Opener._previousWindow()
    if !self._isWindowUsable(winnr("#")) && self._firstUsableWindow() ==# -1
        call self._newSplit()
    else
        try
            if !self._isWindowUsable(winnr("#"))
                call nerdtree#exec(self._firstUsableWindow() . "wincmd w")
            else
                call nerdtree#exec('wincmd p')
            endif
        catch /^Vim\%((\a\+)\)\=:E37/
            call g:NERDTree.CursorToTreeWin()
            throw "NERDTree.FileAlreadyOpenAndModifiedError: ". self._path.str() ." is already open and modified."
        catch /^Vim\%((\a\+)\)\=:/
            echo v:exception
        endtry
    endif
endfunction

" FUNCTION: Opener._restoreCursorPos() {{{1
function! s:Opener._restoreCursorPos()
    call nerdtree#exec('normal ' . self._tabnr . 'gt')
    call nerdtree#exec(bufwinnr(self._bufnr) . 'wincmd w')
endfunction

" FUNCTION: Opener._saveCursorPos() {{{1
function! s:Opener._saveCursorPos()
    let self._bufnr = bufnr("")
    let self._tabnr = tabpagenr()
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
