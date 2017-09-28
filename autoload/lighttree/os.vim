function! lighttree#os#is_windows()
    return has("win16") || has("win32") || has("win64")
endfunction
