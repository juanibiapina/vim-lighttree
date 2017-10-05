function! lighttree#menu#show(node)
    let mc = g:NERDTreeMenuController.New(g:NERDTreeMenuItem.All())
    call mc.showMenu()
endfunction
