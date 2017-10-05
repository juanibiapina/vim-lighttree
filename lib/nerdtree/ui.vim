let s:UI = {}
let g:NERDTreeUI = s:UI

"prints out the quick help
function! s:UI._dumpHelp()
    if self.getShowHelp()
        let help  = "\" ----------------------------\n"
        let help .= "\" File node mappings~\n"
        let help .= "\" <CR>,\n"
        let help .= "\" ". g:LightTreeMapActivateNode .": open in current window\n"

        let help .= "\"\n\" ----------------------------\n"
        let help .= "\" Directory node mappings~\n"
        let help .= "\" ". g:LightTreeMapActivateNode .": open & close node\n"
        let help .= "\" ". g:LightTreeMapOpenRecursively .": recursively open node\n"
        let help .= "\" ". g:LightTreeMapCloseDir .": close parent of node\n"
        let help .= "\" ". g:LightTreeMapCloseChildren .": close all child nodes of\n"
        let help .= "\"    current node recursively\n"

        let help .= "\"\n\" ----------------------------\n"
        let help .= "\" Tree navigation mappings~\n"
        let help .= "\" ". g:LightTreeMapJumpRoot .": go to root\n"
        let help .= "\" ". g:LightTreeMapJumpParent .": go to parent\n"
        let help .= "\" ". g:LightTreeMapJumpNextSibling .": go to next sibling\n"
        let help .= "\" ". g:LightTreeMapJumpPrevSibling .": go to prev sibling\n"

        let help .= "\"\n\" ----------------------------\n"
        let help .= "\" Filesystem mappings~\n"
        let help .= "\" ". g:LightTreeMapChangeRoot .": change tree root to the\n"
        let help .= "\"    selected dir\n"
        let help .= "\" ". g:LightTreeMapUpdir .": move tree root up a dir\n"
        let help .= "\" ". g:LightTreeMapUpdirKeepOpen .": move tree root up a dir\n"
        let help .= "\"    but leave old root open\n"
        let help .= "\" ". g:LightTreeMapRefresh .": refresh cursor dir\n"
        let help .= "\" ". g:LightTreeMapRefreshRoot .": refresh current root\n"
        let help .= "\" ". g:LightTreeMapMenu .": Show menu\n"
        let help .= "\" ". g:LightTreeMapChdir .":change the CWD to the\n"
        let help .= "\"    selected dir\n"
        let help .= "\" ". g:LightTreeMapCWD .":change tree root to CWD\n"

        let help .= "\"\n\" ----------------------------\n"
        let help .= "\" Tree filtering mappings~\n"
        let help .= "\" ". g:LightTreeMapToggleHidden .": hidden files (" . (self.getShowHidden() ? "on" : "off") . ")\n"
        let help .= "\" ". g:LightTreeMapToggleFilters .": file filters (" . (self.isIgnoreFilterEnabled() ? "on" : "off") . ")\n"
        let help .= "\" ". g:LightTreeMapToggleFiles .": files (" . (self.getShowFiles() ? "on" : "off") . ")\n"

        let help .= "\"\n\" ----------------------------\n"
        let help .= "\" Other mappings~\n"
        let help .= "\" ". g:LightTreeMapHelp .": toggle help\n"
        silent! put =help
    endif
endfunction


function! s:UI.New(nerdtree)
    let newObj = copy(self)
    let newObj.nerdtree = a:nerdtree
    let newObj._showHelp = 0
    let newObj._ignoreEnabled = 1
    let newObj._showFiles = 1
    let newObj._showHidden = g:LightTreeShowHidden

    return newObj
endfunction

"Gets the full path to the node that is rendered on the given line number
"
"Args:
"ln: the line number to get the path for
"
"Return:
"A path if a node was selected, {} if nothing is selected.
"If the 'up a dir' line was selected then the path to the parent of the
"current root is returned
function! s:UI.getPath(ln)
    let rootLine = self.getRootLineNum()

    "check to see if we have the root node
    if a:ln == rootLine
        return self.nerdtree.root.path
    endif

    let line = getline(a:ln)

    let indent = self._indentLevelFor(line)

    "remove the tree parts and the leading space
    let curFile = self._stripMarkup(line, 0)

    let wasdir = 0
    if curFile =~# '/$'
        let wasdir = 1
        let curFile = substitute(curFile, '/\?$', '/', "")
    endif

    let dir = ""
    let lnum = a:ln
    while lnum > 0
        let lnum = lnum - 1
        let curLine = getline(lnum)
        let curLineStripped = self._stripMarkup(curLine, 1)

        "have we reached the top of the tree?
        if lnum == rootLine
            let dir = self.nerdtree.root.path.str({'format': 'UI'}) . dir
            break
        endif

        if curLineStripped =~# '/$'
            let lpindent = self._indentLevelFor(curLine)
            if lpindent < indent
                let indent = indent - 1

                let dir = substitute (curLineStripped,'^\\', "", "") . dir
                continue
            endif
        endif
    endwhile

    let curFile = self.nerdtree.root.path.drive . dir . curFile
    return g:NERDTreePath.New(curFile)
endfunction

"returns the line number this node is rendered on, or -1 if it isnt rendered
function! s:UI.getLineNum(file_node)
    "if the node is the root then return the root line no.
    if a:file_node.isRoot()
        return self.getRootLineNum()
    endif

    let totalLines = line("$")

    "the path components we have matched so far
    let pathcomponents = [substitute(self.nerdtree.root.path.str({'format': 'UI'}), '/ *$', '', '')]
    "the index of the component we are searching for
    let curPathComponent = 1

    let fullpath = a:file_node.path.str({'format': 'UI'})

    let lnum = self.getRootLineNum()
    while lnum > 0
        let lnum = lnum + 1
        "have we reached the bottom of the tree?
        if lnum ==# totalLines+1
            return -1
        endif

        let curLine = getline(lnum)

        let indent = self._indentLevelFor(curLine)
        if indent ==# curPathComponent
            let curLine = self._stripMarkup(curLine, 1)

            let curPath =  join(pathcomponents, '/') . '/' . curLine
            if stridx(fullpath, curPath, 0) ==# 0
                if fullpath ==# curPath || strpart(fullpath, len(curPath)-1,1) ==# '/'
                    let curLine = substitute(curLine, '/ *$', '', '')
                    call add(pathcomponents, curLine)
                    let curPathComponent = curPathComponent + 1

                    if fullpath ==# curPath
                        return lnum
                    endif
                endif
            endif
        endif
    endwhile
    return -1
endfunction

"gets the line number of the root node
function! s:UI.getRootLineNum()
    let rootLine = 1
    while getline(rootLine) !~# '^\(/\|<\)'
        let rootLine = rootLine + 1
    endwhile
    return rootLine
endfunction

function! s:UI.getShowFiles()
    return self._showFiles
endfunction

function! s:UI.getShowHelp()
    return self._showHelp
endfunction

function! s:UI.getShowHidden()
    return self._showHidden
endfunction

function! s:UI._indentLevelFor(line)
    "have to do this work around because match() returns bytes, not chars
    let numLeadBytes = match(a:line, '\M\[^ '.g:NERDTreeDirArrowExpandable.g:NERDTreeDirArrowCollapsible.']')
    " The next line is a backward-compatible workaround for strchars(a:line(0:numLeadBytes-1]). strchars() is in 7.3+
    let leadChars = len(split(a:line[0:numLeadBytes-1], '\zs'))

    return leadChars / s:UI.IndentWid()
endfunction

function! s:UI.IndentWid()
    return 2
endfunction

function! s:UI.isIgnoreFilterEnabled()
    return self._ignoreEnabled == 1
endfunction

function! s:UI.MarkupReg()
    return '^\(['.g:NERDTreeDirArrowExpandable.g:NERDTreeDirArrowCollapsible.'] \| \+['.g:NERDTreeDirArrowExpandable.g:NERDTreeDirArrowCollapsible.'] \| \+\)'
endfunction

function! s:UI.setShowHidden(val)
    let self._showHidden = a:val
endfunction

"returns the given line with all the tree parts stripped off
"
"Args:
"line: the subject line
"removeLeadingSpaces: 1 if leading spaces are to be removed (leading spaces =
"any spaces before the actual text of the node)
function! s:UI._stripMarkup(line, removeLeadingSpaces)
    let line = a:line
    "remove the tree parts and the leading space
    let line = substitute (line, g:NERDTreeUI.MarkupReg(),"","")

    "strip off any read only flag
    let line = substitute (line, ' \['.g:NERDTreeGlyphReadOnly.'\]', "","")

    "strip off any executable flags
    let line = substitute (line, '*\ze\($\| \)', "","")

    "strip off any generic flags
    let line = substitute (line, '\[[^]]*\]', "","")

    let wasdir = 0
    if line =~# '/$'
        let wasdir = 1
    endif
    let line = substitute (line,' -> .*',"","") " remove link to
    if wasdir ==# 1
        let line = substitute (line, '/\?$', '/', "")
    endif

    if a:removeLeadingSpaces
        let line = substitute (line, '^ *', '', '')
    endif

    return line
endfunction

function! s:UI.render()
    setlocal modifiable

    "remember the top line of the buffer and the current line so we can
    "restore the view exactly how it was
    let curLine = line(".")
    let curCol = col(".")
    let topLine = line("w0")

    "delete all lines in the buffer (being careful not to clobber a register)
    silent keepjumps 1,$delete _

    call self._dumpHelp()

    "draw the header line
    let header = self.nerdtree.root.path.str({'format': 'UI', 'truncateTo': winwidth(0)})
    call setline(line(".")+1, header)
    call cursor(line(".")+1, col("."))

    "draw the tree
    silent put =self.nerdtree.root.renderToString()

    "delete the blank line at the top of the buffer
    silent keepjumps 1,1delete _

    "restore the view
    let old_scrolloff=&scrolloff
    let &scrolloff=0
    call cursor(topLine, 1)
    normal! zt
    call cursor(curLine, curCol)
    let &scrolloff = old_scrolloff

    setlocal nomodifiable
endfunction


"Renders the tree and ensures the cursor stays on the current node or the
"current nodes parent if it is no longer available upon re-rendering
function! s:UI.renderViewSavingPosition()
    let currentNode = g:NERDTreeFileNode.GetSelected()

    "go up the tree till we find a node that will be visible or till we run
    "out of nodes
    while currentNode != {} && !currentNode.isVisible() && !currentNode.isRoot()
        let currentNode = currentNode.parent
    endwhile

    call self.render()

    if currentNode != {}
        call currentNode.putCursorHere(0)
    endif
endfunction

function! s:UI.toggleHelp()
    let self._showHelp = !self._showHelp
endfunction

" toggles the use of the LightTreeIgnore option
function! s:UI.toggleIgnoreFilter()
    let self._ignoreEnabled = !self._ignoreEnabled
    call self.renderViewSavingPosition()
endfunction

" toggles the display of hidden files
function! s:UI.toggleShowFiles()
    let self._showFiles = !self._showFiles
    call self.renderViewSavingPosition()
endfunction

" toggles the display of hidden files
function! s:UI.toggleShowHidden()
    let self._showHidden = !self._showHidden
    call self.renderViewSavingPosition()
endfunction
