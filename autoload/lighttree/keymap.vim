function! lighttree#keymap#create(key, scope, callback)
    call s:remove(a:key, a:scope)

    call add(s:keymaps(), { 'key': a:key, 'scope': a:scope, 'callback': a:callback })
endfunction

function! lighttree#keymap#invoke(key)
    let node = g:NERDTreeFileNode.GetSelected()
    if !empty(node)
        let km = s:find_for(a:key, "Node")
        if !empty(km)
            return s:invoke(km, node)
        endif
    endif

    "try all
    let km = s:find_for(a:key, "all")
    if !empty(km)
        return s:invoke(km)
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

function! s:find_for(key, scope)
    for i in s:keymaps()
         if i.key ==# a:key && i.scope ==# a:scope
            return i
        endif
    endfor
    return {}
endfunction

function! s:invoke(keymap, ...)
    let Callback = function(a:keymap.callback)
    if a:0
        call Callback(a:1)
    else
        call Callback()
    endif
endfunction

function! s:bind(keymap)
    " If the key sequence we're trying to map contains any '<>' notation, we
    " must replace each of the '<' characters with '<lt>' to ensure the string
    " is not translated into its corresponding keycode during the later part
    " of the map command below
    " :he <>
    let specialNotationRegex = '\m<\([[:alnum:]_-]\+>\)'
    if a:keymap.key =~# specialNotationRegex
        let keymapInvokeString = substitute(a:keymap.key, specialNotationRegex, '<lt>\1', 'g')
    else
        let keymapInvokeString = a:keymap.key
    endif

    exec 'nnoremap <buffer> <silent> '. a:keymap.key . ' :call lighttree#keymap#invoke("'. keymapInvokeString .'")<cr>'
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
