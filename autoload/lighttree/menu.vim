function! lighttree#menu#show(_node)
    call s:save_options()

    try
        call s:set_options()

        let index = -1
        let done = 0

        while !done
            redraw!

            call s:print_items()

            let key = nr2char(getchar())

            if key == nr2char(27) "escape
                let done = 1
            else
                let index = s:index_for(key)
                if index != -1
                    let done = 1
                endif
            endif
        endwhile
    finally
        call s:restore_options()
    endtry

    if index != -1
        let item = s:get_item(index)
        call {item.callback}()
    endif
endfunction

function! s:all_items()
    if !exists("s:menu_items")
        let s:menu_items = []

        call s:add_item('a', '(a)dd a childnode', 'lighttree#fs_menu#add_node')
        call s:add_item('m', '(m)ove the current node', 'lighttree#fs_menu#move_node')
        call s:add_item('d', '(d)elete the current node', 'lighttree#fs_menu#remove_node')

        if has("gui_mac") || has("gui_macvim") || has("mac")
            call s:add_item('r', '(r)eveal in Finder the current node', 'lighttree#fs_menu#reveal_in_finder')
            call s:add_item('o', '(o)pen the current node with system editor', 'lighttree#fs_menu#exec_file')
            call s:add_item('q', '(q)uicklook the current node', 'lighttree#fs_menu#quick_look')
        endif

        if g:NERDTreePath.CopyingSupported()
            call s:add_item('c', '(c)opy the current node', 'lighttree#fs_menu#copy_node')
        endif

    endif

    return s:menu_items
endfunction

function! s:add_item(shortcut, text, callback)
    call add(s:menu_items, { 'shortcut': a:shortcut, 'text': a:text, 'callback': a:callback })
endfunction


function! s:save_options()
    let s:old_lazyredraw = &lazyredraw
    let s:old_cmdheight = &cmdheight
endfunction

function! s:set_options()
    set nolazyredraw
    let &cmdheight = len(s:all_items()) + 2
endfunction

function! s:restore_options()
    let &cmdheight = s:old_cmdheight
    let &lazyredraw = s:old_lazyredraw
endfunction

function! s:print_items()
    echo " "
    let items = s:all_items()
    for i in range(0, len(items) - 1)
        echo " " . items[i].text
    endfor
endfunction

function! s:index_for(shortcut)
    let items = s:all_items()
    for i in range(0, len(items) - 1)
        if items[i].shortcut == a:shortcut
            return i
        endif
    endfor

    return -1
endfunction

function! s:get_item(index)
    return s:all_items()[a:index]
endfunction
