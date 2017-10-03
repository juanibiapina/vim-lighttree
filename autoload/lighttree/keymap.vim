function! lighttree#keymap#create(options)
    call g:NERDTreeKeyMap.Create(a:options)
endfunction

function! lighttree#keymap#invoke(key)
    call g:NERDTreeKeyMap.Invoke(a:key)
endfunction
