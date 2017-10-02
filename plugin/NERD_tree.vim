if exists("loaded_light_tree")
    finish
endif
if v:version < 700
    echoerr "NERDTree: this plugin requires vim >= 7."
    finish
endif
let loaded_light_tree = 1

"for line continuation - i.e dont want C in &cpo
let s:old_cpo = &cpo
set cpo&vim

"This function is used to initialise a given variable to a given value. The
"variable is only initialised if it does not exist prior
"
"Args:
"var: the name of the var to be initialised
"value: the value to initialise var to
"
"Returns:
"1 if the var is set, 0 otherwise
function! s:initVariable(var, value)
    if !exists(a:var)
        exec 'let ' . a:var . ' = ' . "'" . substitute(a:value, "'", "''", "g") . "'"
        return 1
    endif
    return 0
endfunction

"SECTION: Init variable calls and other random constants {{{2
call s:initVariable("g:LightTreeCaseSensitiveSort", 0)
call s:initVariable("g:LightTreeNaturalSort", 0)
if !exists("g:NERDTreeIgnore")
    let g:NERDTreeIgnore = ['\~$']
endif
call s:initVariable("g:NERDTreeHighlightCursorline", 1)
call s:initVariable("g:NERDTreeHijackNetrw", 1)
call s:initVariable("g:NERDTreeNotificationThreshold", 100)
call s:initVariable("g:NERDTreeRespectWildIgnore", 0)
call s:initVariable("g:NERDTreeShowFiles", 1)
call s:initVariable("g:NERDTreeShowHidden", 0)
call s:initVariable("g:NERDTreeShowLineNumbers", 0)
call s:initVariable("g:NERDTreeSortDirs", 1)

if !lighttree#os#is_windows()
    call s:initVariable("g:NERDTreeDirArrowExpandable", "▸")
    call s:initVariable("g:NERDTreeDirArrowCollapsible", "▾")
else
    call s:initVariable("g:NERDTreeDirArrowExpandable", "+")
    call s:initVariable("g:NERDTreeDirArrowCollapsible", "~")
endif
call s:initVariable("g:NERDTreeCascadeOpenSingleChildDir", 1)

if !exists("g:NERDTreeSortOrder")
    let g:NERDTreeSortOrder = ['\/$', '*', '\.swp$',  '\.bak$', '\~$']
else
    "if there isnt a * in the sort sequence then add one
    if count(g:NERDTreeSortOrder, '*') < 1
        call add(g:NERDTreeSortOrder, '*')
    endif
endif

call s:initVariable("g:NERDTreeGlyphReadOnly", "RO")

if !exists('g:NERDTreeStatusline')

    "the exists() crap here is a hack to stop vim spazzing out when
    "loading a session that was created with an open nerd tree. It spazzes
    "because it doesnt store b:NERDTree(its a b: var, and its a hash)
    let g:NERDTreeStatusline = "%{exists('b:NERDTree')?b:NERDTree.root.path.str():''}"

endif

"init the shell commands that will be used to copy nodes, and remove dir trees
"
"Note: the space after the command is important
if lighttree#os#is_windows()
    call s:initVariable("g:NERDTreeRemoveDirCmd", 'rmdir /s /q ')
    call s:initVariable("g:NERDTreeCopyDirCmd", 'xcopy /s /e /i /y /q ')
    call s:initVariable("g:NERDTreeCopyFileCmd", 'copy /y ')
else
    call s:initVariable("g:NERDTreeRemoveDirCmd", 'rm -rf ')
    call s:initVariable("g:NERDTreeCopyCmd", 'cp -r ')
endif


"SECTION: Init variable calls for key mappings {{{2
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
runtime lib/nerdtree/menu_controller.vim
runtime lib/nerdtree/menu_item.vim
runtime lib/nerdtree/key_map.vim
runtime lib/nerdtree/tree_file_node.vim
runtime lib/nerdtree/tree_dir_node.vim
runtime lib/nerdtree/creator.vim
runtime lib/nerdtree/flag_set.vim
runtime lib/nerdtree/nerdtree.vim
runtime lib/nerdtree/ui.vim
runtime lib/nerdtree/event.vim
runtime lib/nerdtree/notifier.vim

call lighttree#ui_glue#setupCommands()

augroup NERDTree
    "disallow insert mode in the NERDTree
    exec "autocmd BufEnter ". g:NERDTreeCreator.BufNamePrefix() ."* stopinsert"
augroup END

if g:NERDTreeHijackNetrw
    function! s:checkForBrowse(dir)
        if !isdirectory(a:dir)
            return
        endif

        " make netrw buffer disappear when lighttree buffer is opened
        setlocal bufhidden=wipe

        call g:NERDTreeCreator.RestoreOrCreateBuffer(a:dir)
    endfunction

    augroup NERDTreeHijackNetrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        au BufEnter,VimEnter * call s:checkForBrowse(expand("<amatch>"))
    augroup END
endif

" SECTION: Public API {{{1
"============================================================
function! NERDTreeAddMenuItem(options)
    return g:NERDTreeMenuItem.Create(a:options)
endfunction

function! NERDTreeAddKeyMap(options)
    call g:NERDTreeKeyMap.Create(a:options)
endfunction

function! NERDTreeAddPathFilter(callback)
    call g:NERDTree.AddPathFilter(a:callback)
endfunction

call lighttree#ui_glue#createDefaultBindings()

"load all nerdtree plugins
runtime! nerdtree_plugin/**/*.vim

"reset &cpo back to users setting
let &cpo = s:old_cpo

" vim: set sw=4 sts=4 et fdm=marker:
