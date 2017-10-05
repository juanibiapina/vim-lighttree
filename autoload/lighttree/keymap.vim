function! lighttree#keymap#create(key, scope, callback)
    call s:remove(a:key, a:scope)

    call add(s:keymaps(), { 'key': a:key, 'scope': a:scope, 'callback': a:callback })
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

function! lighttree#keymap#bind_all()
    for keymap in s:keymaps()
        call s:bind(keymap)
    endfor
endfunction

function! s:keymaps()
    if !exists("s:keyMaps")
        let s:keyMaps = []
    endif

    return s:keyMaps
endfunction

function! s:remove(key, scope)
    let maps = s:keymaps()
    for i in range(len(maps))
         if maps[i].key ==# a:key && maps[i].scope ==# a:scope
            call remove(maps, i)
        endif
    endfor
endfunction

function! s:bind(keymap)
    exec 'nnoremap <buffer> <silent> '. a:keymap.key . ' :call lighttree#keymap#invoke("' . a:keymap.callback . '", "' . a:keymap.scope . '")<cr>'
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
