function! lighttree#keymap#create(options)
    call g:NERDTreeKeyMap.Create(a:options)
endfunction

function! lighttree#keymap#invoke(key)
    call g:NERDTreeKeyMap.Invoke(a:key)
endfunction

function! lighttree#keymap#all()
    call g:NERDTreeKeyMap.All()
endfunction

function! lighttree#keymap#bind_all()
    for keymap in g:NERDTreeKeyMap.All()
        call keymap.bind()
    endfor
endfunction
