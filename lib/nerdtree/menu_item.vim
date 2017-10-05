let s:MenuItem = {}
let g:NERDTreeMenuItem = s:MenuItem

function! s:MenuItem.All()
    if !exists("s:menuItems")
        let s:menuItems = []
    endif
    return s:menuItems
endfunction

"make a new menu item and add it to the global list
function! s:MenuItem.Create(options)
    let newMenuItem = copy(self)

    let newMenuItem.text = a:options['text']
    let newMenuItem.shortcut = a:options['shortcut']

    let newMenuItem.callback = -1
    if has_key(a:options, 'callback')
        let newMenuItem.callback = a:options['callback']
    endif

    call add(s:MenuItem.All(), newMenuItem)

    return newMenuItem
endfunction

function! s:MenuItem.execute()
    if self.callback != -1
        call {self.callback}()
    endif
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
