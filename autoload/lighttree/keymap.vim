function! lighttree#keymap#bind_all()
    call s:bind("<CR>", "Node", "lighttree#ui_glue#activate_node")

    call s:bind(g:LightTreeMapActivateNode, "Node", "lighttree#ui_glue#activate_node")

    call s:bind(g:LightTreeMapOpenRecursively, "Node", "lighttree#ui_glue#openNodeRecursively")

    call s:bind(g:LightTreeMapUpdir, "all", "lighttree#ui_glue#upDirCurrentRootClosed")
    call s:bind(g:LightTreeMapUpdirKeepOpen, "all", "lighttree#ui_glue#upDirCurrentRootOpen")
    call s:bind(g:LightTreeMapChangeRoot, "Node", "lighttree#ui_glue#chRoot")

    call s:bind(g:LightTreeMapChdir, "Node", "lighttree#ui_glue#chCwd")

    call s:bind(g:LightTreeMapCWD, "all", "lighttree#ui_glue#chRootCwd")

    call s:bind(g:LightTreeMapRefreshRoot, "all", "lighttree#ui_glue#refreshRoot")
    call s:bind(g:LightTreeMapRefresh, "Node", "lighttree#ui_glue#refreshCurrent")

    call s:bind(g:LightTreeMapHelp, "all", "lighttree#ui_glue#displayHelp")
    call s:bind(g:LightTreeMapToggleHidden, "all", "lighttree#ui_glue#toggleShowHidden")
    call s:bind(g:LightTreeMapToggleFilters, "all", "lighttree#ui_glue#toggleIgnoreFilter")
    call s:bind(g:LightTreeMapToggleFiles, "all", "lighttree#ui_glue#toggleShowFiles")

    call s:bind(g:LightTreeMapCloseDir, "Node", "lighttree#ui_glue#closeParentDir")
    call s:bind(g:LightTreeMapCloseChildren, "Node", "lighttree#ui_glue#closeChildren")

    call s:bind(g:LightTreeMapMenu, "Node", "lighttree#menu#show")

    call s:bind(g:LightTreeMapJumpParent, "Node", "lighttree#ui_glue#jumpToParent")
    call s:bind(g:LightTreeMapJumpRoot, "all", "lighttree#ui_glue#jumpToRoot")
    call s:bind(g:LightTreeMapJumpNextSibling, "Node", "lighttree#ui_glue#jumpToNextSibling")
    call s:bind(g:LightTreeMapJumpPrevSibling, "Node", "lighttree#ui_glue#jumpToPrevSibling")
endfunction

function! lighttree#keymap#invoke(callback, scope)
    if a:scope ==# "all"
        return function(a:callback)()
    endif

    let node = g:NERDTreeFileNode.GetSelected()

    if !empty(node)
        if a:scope ==# "Node"
            return function(a:callback)(node)
        endif
    endif
endfunction

function! s:bind(key, scope, callback)
    exec 'nnoremap <buffer> <silent> '. a:key . ' :call lighttree#keymap#invoke("' . a:callback . '", "' . a:scope . '")<cr>'
endfunction
