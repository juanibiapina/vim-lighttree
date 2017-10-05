if exists("loaded_light_tree") || &cp
    finish
endif
let loaded_light_tree = 1

function! s:initVariable(var, value)
    if !exists(a:var)
        exec 'let ' . a:var . ' = ' . "'" . substitute(a:value, "'", "''", "g") . "'"
        return 1
    endif
    return 0
endfunction

call s:initVariable("g:LightTreeCaseSensitiveSort", 0)
call s:initVariable("g:LightTreeNaturalSort", 0)
if !exists("g:LightTreeIgnore")
    let g:LightTreeIgnore = ['\~$']
endif
call s:initVariable("g:LightTreeHighlightCursorline", 1)
call s:initVariable("g:LightTreeHijackNetrw", 1)
call s:initVariable("g:LightTreeNotificationThreshold", 100)
call s:initVariable("g:LightTreeRespectWildIgnore", 0)
call s:initVariable("g:LightTreeShowHidden", 0)
call s:initVariable("g:LightTreeShowLineNumbers", 0)

if lighttree#os#is_windows()
    call s:initVariable("g:NERDTreeDirArrowExpandable", "+")
    call s:initVariable("g:NERDTreeDirArrowCollapsible", "~")

    call s:initVariable("g:NERDTreeRemoveDirCmd", 'rmdir /s /q ')
    call s:initVariable("g:NERDTreeCopyDirCmd", 'xcopy /s /e /i /y /q ')
    call s:initVariable("g:NERDTreeCopyFileCmd", 'copy /y ')
else
    call s:initVariable("g:NERDTreeDirArrowExpandable", "▸")
    call s:initVariable("g:NERDTreeDirArrowCollapsible", "▾")

    call s:initVariable("g:NERDTreeRemoveDirCmd", 'rm -rf ')
    call s:initVariable("g:NERDTreeCopyCmd", 'cp -r ')
endif

call s:initVariable("g:LightTreeCascadeOpenSingleChildDir", 1)

if !exists("g:LightTreeSortOrder")
    let g:LightTreeSortOrder = ['\/$', '*', '\.swp$',  '\.bak$', '\~$']
else
    if count(g:LightTreeSortOrder, '*') < 1
        call add(g:LightTreeSortOrder, '*')
    endif
endif

call s:initVariable("g:NERDTreeGlyphReadOnly", "RO")

if !exists('g:LightTreeStatusline')
    "the exists() crap here is a hack to stop vim spazzing out when
    "loading a session that was created with an open nerd tree. It spazzes
    "because it doesnt store b:NERDTree(its a b: var, and its a hash)
    let g:LightTreeStatusline = "%{exists('b:NERDTree')?b:NERDTree.root.path.str():''}"
endif

call s:initVariable("g:LightTreeMapActivateNode", "o")
call s:initVariable("g:LightTreeMapChangeRoot", "C")
call s:initVariable("g:LightTreeMapChdir", "cd")
call s:initVariable("g:LightTreeMapCloseChildren", "X")
call s:initVariable("g:LightTreeMapCloseDir", "x")
call s:initVariable("g:LightTreeMapMenu", "m")
call s:initVariable("g:LightTreeMapHelp", "?")
call s:initVariable("g:LightTreeMapJumpNextSibling", "J")
call s:initVariable("g:LightTreeMapJumpParent", "p")
call s:initVariable("g:LightTreeMapJumpPrevSibling", "K")
call s:initVariable("g:LightTreeMapJumpRoot", "P")
call s:initVariable("g:LightTreeMapOpenRecursively", "O")
call s:initVariable("g:LightTreeMapRefresh", "r")
call s:initVariable("g:LightTreeMapRefreshRoot", "R")
call s:initVariable("g:LightTreeMapToggleFiles", "F")
call s:initVariable("g:LightTreeMapToggleFilters", "f")
call s:initVariable("g:LightTreeMapToggleHidden", "I")
call s:initVariable("g:LightTreeMapUpdir", "u")
call s:initVariable("g:LightTreeMapUpdirKeepOpen", "U")
call s:initVariable("g:LightTreeMapCWD", "CD")

runtime lib/nerdtree/path.vim
runtime lib/nerdtree/tree_file_node.vim
runtime lib/nerdtree/tree_dir_node.vim
runtime lib/nerdtree/creator.vim
runtime lib/nerdtree/nerdtree.vim
runtime lib/nerdtree/ui.vim
runtime lib/nerdtree/fs_menu.vim

call lighttree#ui_glue#setupCommands()

augroup NERDTree
    exec "autocmd BufEnter ". g:NERDTreeCreator.BufNamePrefix() ."* stopinsert"
augroup END

if g:LightTreeHijackNetrw
    function! s:checkForBrowse(dir)
        if !isdirectory(a:dir)
            return
        endif

        " make netrw buffer disappear when lighttree buffer is opened
        setlocal bufhidden=wipe

        call g:NERDTreeCreator.RestoreOrCreateBuffer(a:dir)
    endfunction

    augroup LightTreeHijackNetrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        au BufEnter,VimEnter * call s:checkForBrowse(expand("<amatch>"))
    augroup END
endif

call lighttree#ui_glue#createDefaultBindings()

" vim: set sw=4 sts=4 et fdm=marker:
