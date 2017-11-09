syn match LightTreeIgnore #\~#
exec 'syn match LightTreeIgnore #\['.g:NERDTreeGlyphReadOnly.'\]#'

"quickhelp syntax elements
syn match NERDTreeHelpKey #" \{1,2\}[^ ]*:#ms=s+2,me=e-1
syn match NERDTreeHelpKey #" \{1,2\}[^ ]*,#ms=s+2,me=e-1
syn match NERDTreeHelpTitle #" .*\~$#ms=s+2,me=e-1
syn match NERDTreeToggleOn #(on)#ms=s+1,he=e-1
syn match NERDTreeToggleOff #(off)#ms=e-3,me=e-1
syn match NERDTreeHelpCommand #" :.\{-}\>#hs=s+3
syn match NERDTreeHelp  #^".*# contains=NERDTreeHelpKey,NERDTreeHelpTitle,LightTreeIgnore,NERDTreeToggleOff,NERDTreeToggleOn,NERDTreeHelpCommand

"highlighting for sym links
syn match NERDTreeLinkTarget #->.*# containedin=NERDTreeDir,NERDTreeFile
syn match NERDTreeLinkFile #.* ->#me=e-3 containedin=NERDTreeFile
syn match NERDTreeLinkDir #.*/ ->#me=e-3 containedin=NERDTreeDir

"highlighing for directory nodes and file nodes
syn match NERDTreeDirSlash #/# containedin=NERDTreeDir

exec 'syn match NERDTreeClosable #' . escape(g:LightTreeDirArrowCollapsible, '~') . '\ze .*/# containedin=NERDTreeDir,NERDTreeFile'
exec 'syn match NERDTreeOpenable #' . escape(g:LightTreeDirArrowExpandable, '~') . '\ze .*/# containedin=NERDTreeDir,NERDTreeFile'

let s:dirArrows = escape(g:LightTreeDirArrowCollapsible, '~]\-').escape(g:LightTreeDirArrowExpandable, '~]\-')
exec 'syn match NERDTreeDir #[^'.s:dirArrows.' ].*/#'
syn match NERDTreeExecFile  #^ .*\*\($\| \)# contains=NERDTreeRO
exec 'syn match NERDTreeFile  #^[^"\.'.s:dirArrows.'] *[^'.s:dirArrows.']*# contains=NERDTreeLink,NERDTreeRO,NERDTreeExecFile'

"highlighting for readonly files
exec 'syn match NERDTreeRO # *\zs.*\ze \['.g:NERDTreeGlyphReadOnly.'\]# contains=LightTreeIgnore,NERDTreeFile'

syn match NERDTreeFlags #^ *\zs\[.\]# containedin=NERDTreeFile,NERDTreeExecFile
syn match NERDTreeFlags #\[.\]# containedin=NERDTreeDir

syn match NERDTreeCWD #^[</].*$#

hi def link NERDTreePart Special
hi def link NERDTreePartFile Type
hi def link NERDTreeExecFile Title
hi def link NERDTreeDirSlash Identifier

hi def link NERDTreeHelp String
hi def link NERDTreeHelpKey Identifier
hi def link NERDTreeHelpCommand Identifier
hi def link NERDTreeHelpTitle Macro
hi def link NERDTreeToggleOn Question
hi def link NERDTreeToggleOff WarningMsg

hi def link NERDTreeLinkTarget Type
hi def link NERDTreeLinkFile Macro
hi def link NERDTreeLinkDir Macro

hi def link NERDTreeDir Directory
hi def link NERDTreeFile Normal
hi def link NERDTreeCWD Statement
hi def link NERDTreeOpenable Directory
hi def link NERDTreeClosable Directory
hi def link LightTreeIgnore ignore
hi def link NERDTreeRO WarningMsg
hi def link NERDTreeFlags Number

hi def link NERDTreeCurrentNode Search
