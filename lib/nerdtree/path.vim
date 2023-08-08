let s:NERDTreeSortStarIndex = index(g:LightTreeSortOrder, '*')
lockvar s:NERDTreeSortStarIndex

let s:Path = {}
let g:NERDTreePath = s:Path

function! s:Path.AbsolutePathFor(str)
    let prependCWD = 0
    let prependCWD = a:str !~# '^/'

    let toReturn = a:str
    if prependCWD
        let toReturn = getcwd() . s:Path.Slash() . a:str
    endif

    return toReturn
endfunction

function! s:Path.cacheDisplayString() abort
    let self.cachedDisplayString = self.getLastPathComponent(1)

    if self.isExecutable
        let self.cachedDisplayString = self.cachedDisplayString . '*'
    endif

    if self.isSymLink
        let self.cachedDisplayString .=  ' -> ' . self.symLinkDest
    endif

    if self.isReadOnly
        let self.cachedDisplayString .=  ' ['.g:LightTreeGlyphReadOnly.']'
    endif
endfunction

function! s:Path.changeToDir()
    let dir = self.str({'format': 'Cd'})
    if self.isDirectory ==# 0
        let dir = self.getParent().str({'format': 'Cd'})
    endif

    try
        execute "cd " . dir
        call lighttree#echo("CWD is now: " . getcwd())
    catch
        throw "NERDTree.PathChangeError: cannot change CWD to " . dir
    endtry
endfunction

"
" Compares this Path to the given path and returns 0 if they are equal, -1 if
" this Path is "less than" the given path, or 1 if it is "greater".
"
" Args:
" path: the path object to compare this to
"
" Return:
" 1, -1 or 0
function! s:Path.compareTo(path)
    let thisPath = self.getLastPathComponent(1)
    let thatPath = a:path.getLastPathComponent(1)

    "if the paths are the same then clearly we return 0
    if thisPath ==# thatPath
        return 0
    endif

    let thisSS = self.getSortOrderIndex()
    let thatSS = a:path.getSortOrderIndex()

    "compare the sort sequences, if they are different then the return
    "value is easy
    if thisSS < thatSS
        return -1
    elseif thisSS > thatSS
        return 1
    else
        "if the sort sequences are the same then compare the paths
        "alphabetically
        let pathCompare = g:LightTreeCaseSensitiveSort ? thisPath <# thatPath : thisPath <? thatPath
        if pathCompare
            return -1
        else
            return 1
        endif
    endif
endfunction

" Factory method.
"
" Creates a path object with the given path. The path is also created on the
" filesystem. If the path already exists, a NERDTree.Path.Exists exception is
" thrown. If any other errors occur, a NERDTree.Path exception is thrown.
"
" Args:
" fullpath: the full filesystem path to the file/dir to create
function! s:Path.Create(fullpath)
    "bail if the a:fullpath already exists
    if isdirectory(a:fullpath) || filereadable(a:fullpath)
        throw "NERDTree.CreatePathError: Directory Exists: '" . a:fullpath . "'"
    endif

    try

        "if it ends with a slash, assume its a dir create it
        if a:fullpath =~# '\(\\\|\/\)$'
            "whack the trailing slash off the end if it exists
            let fullpath = substitute(a:fullpath, '\(\\\|\/\)$', '', '')

            call mkdir(fullpath, 'p')

        "assume its a file and create
        else
            call s:Path.createParentDirectories(a:fullpath)
            call writefile([], a:fullpath)
        endif
    catch
        throw "NERDTree.CreatePathError: Could not create path: '" . a:fullpath . "'"
    endtry

    return s:Path.New(a:fullpath)
endfunction

" Copies the file/dir represented by this Path to the given location
"
" Args:
" dest: the location to copy this dir/file to
function! s:Path.copy(dest)
    call s:Path.createParentDirectories(a:dest)

    let cmd_prefix = g:NERDTreeCopyCmd

    let cmd = cmd_prefix . " " . escape(self.str(), self._escChars()) . " " . escape(a:dest, self._escChars())
    let success = system(cmd)
    if v:shell_error != 0
        throw "NERDTree.CopyError: Could not copy ''". self.str() ."'' to: '" . a:dest . "'"
    endif
endfunction

" returns 1 if copy this path to the given location will cause files to
" overwritten
"
" Args:
" dest: the location this path will be copied to
function! s:Path.copyingWillOverwrite(dest)
    if filereadable(a:dest)
        return 1
    endif

    if isdirectory(a:dest)
        let path = s:Path.JoinPathStrings(a:dest, self.getLastPathComponent(0))
        if filereadable(path)
            return 1
        endif
    endif
endfunction

" create parent directories for this path if needed
" without throwing any errors if those directories already exist
"
" Args:
" path: full path of the node whose parent directories may need to be created
function! s:Path.createParentDirectories(path)
    let dir_path = fnamemodify(a:path, ':h')
    if !isdirectory(dir_path)
        call mkdir(dir_path, 'p')
    endif
endfunction

" Deletes the file or directory represented by this path.
"
" Throws NERDTree.Path.Deletion exceptions
function! s:Path.delete()
    if self.isDirectory

        let cmd = g:NERDTreeRemoveDirCmd . self.str({'escape': 1})
        let success = system(cmd)

        if v:shell_error != 0
            throw "NERDTree.PathDeletionError: Could not delete directory: '" . self.str() . "'"
        endif
    else
        let success = delete(self.str())
        if success != 0
            throw "NERDTree.PathDeletionError: Could not delete file: '" . self.str() . "'"
        endif
    endif
endfunction

" Returns a string that specifies how the path should be represented as a
" string
function! s:Path.displayString()
    if self.cachedDisplayString ==# ""
        call self.cacheDisplayString()
    endif

    return self.cachedDisplayString
endfunction

function! s:Path.edit()
    exec "edit " . self.str({'format': 'Edit'})
endfunction

" return 1 if this path points to a location that is readable or is a directory
function! s:Path.exists()
    let p = self.str()
    return filereadable(p) || isdirectory(p)
endfunction

function! s:Path._escChars()
    return " \\`\|\"#%&,?()\*^<>[]$"
endfunction

" Returns this path if it is a directory, else this paths parent.
"
" Return:
" a Path object
function! s:Path.getDir()
    if self.isDirectory
        return self
    else
        return self.getParent()
    endif
endfunction

" Returns a new path object for this paths parent
"
" Return:
" a new Path object
function! s:Path.getParent()
    let path = '/'. join(self.pathSegments[0:-2], '/')

    return s:Path.New(path)
endfunction

" Gets the last part of this path.
"
" Args:
" dirSlash: if 1 then a trailing slash will be added to the returned value for
" directory nodes.
function! s:Path.getLastPathComponent(dirSlash)
    if empty(self.pathSegments)
        return ''
    endif
    let toReturn = self.pathSegments[-1]
    if a:dirSlash && self.isDirectory
        let toReturn = toReturn . '/'
    endif
    return toReturn
endfunction

" returns the index of the pattern in g:LightTreeSortOrder that this path matches
function! s:Path.getSortOrderIndex()
    let i = 0
    while i < len(g:LightTreeSortOrder)
        if  self.getLastPathComponent(1) =~# g:LightTreeSortOrder[i]
            return i
        endif
        let i = i + 1
    endwhile
    return s:NERDTreeSortStarIndex
endfunction

" returns a list of path chunks
function! s:Path._splitChunks(path)
    let chunks = split(a:path, '\(\D\+\|\d\+\)\zs')
    let i = 0
    while i < len(chunks)
        "convert number literals to numbers
        if match(chunks[i], '^\d\+$') == 0
            let chunks[i] = str2nr(chunks[i])
        endif
        let i = i + 1
    endwhile
    return chunks
endfunction

" returns a key used in compare function for sorting
function! s:Path.getSortKey()
    if !exists("self._sortKey")
        let path = self.getLastPathComponent(1)
        if !g:LightTreeCaseSensitiveSort
            let path = tolower(path)
        endif
        if !g:LightTreeNaturalSort
            let self._sortKey = [self.getSortOrderIndex(), path]
        else
            let self._sortKey = [self.getSortOrderIndex()] + self._splitChunks(path)
        endif
    endif

    return self._sortKey
endfunction


" check for unix hidden files
function! s:Path.isUnixHiddenFile()
    return self.getLastPathComponent(0) =~# '^\.'
endfunction

" check for unix path with hidden components
function! s:Path.isUnixHiddenPath()
    if self.getLastPathComponent(0) =~# '^\.'
        return 1
    else
        for segment in self.pathSegments
            if segment =~# '^\.'
                return 1
            endif
        endfor
        return 0
    endif
endfunction

" returns true if this path should be ignored
function! s:Path.ignore(nerdtree)
    "filter out the user specified paths to ignore
    if a:nerdtree.ui.isIgnoreFilterEnabled()
        for i in g:LightTreeIgnore
            if self._ignorePatternMatches(i)
                return 1
            endif
        endfor
    endif

    "dont show hidden files unless instructed to
    if !a:nerdtree.ui.getShowHidden() && self.isUnixHiddenFile()
        return 1
    endif

    if a:nerdtree.ui.getShowFiles() ==# 0 && self.isDirectory ==# 0
        return 1
    endif

    return 0
endfunction

" returns true if this path matches the given ignore pattern
function! s:Path._ignorePatternMatches(pattern)
    let pat = a:pattern
    if strpart(pat,len(pat)-7) == '[[dir]]'
        if !self.isDirectory
            return 0
        endif
        let pat = strpart(pat,0, len(pat)-7)
    elseif strpart(pat,len(pat)-8) == '[[file]]'
        if self.isDirectory
            return 0
        endif
        let pat = strpart(pat,0, len(pat)-8)
    endif

    return self.getLastPathComponent(0) =~# pat
endfunction

" return 1 if this path is somewhere above the given path in the filesystem.
"
" a:path should be a dir
function! s:Path.isAncestor(path)
    if !self.isDirectory
        return 0
    endif

    let this = self.str()
    let that = a:path.str()
    return stridx(that, this) == 0
endfunction

" return 1 if this path is somewhere under the given path in the filesystem.
function! s:Path.isUnder(path)
    if a:path.isDirectory == 0
        return 0
    endif

    let this = self.str()
    let that = a:path.str()
    return stridx(this, that . s:Path.Slash()) == 0
endfunction

function! s:Path.JoinPathStrings(...)
    let components = []
    for i in a:000
        let components = extend(components, split(i, '/'))
    endfor
    return '/' . join(components, '/')
endfunction

" Determines whether 2 path objects are "equal".
" They are equal if the paths they represent are the same
"
" Args:
" path: the other path obj to compare this with
function! s:Path.equals(path)
    return self.str() ==# a:path.str()
endfunction

" The Constructor for the Path object
function! s:Path.New(path)
    let newPath = copy(self)

    call newPath.readInfoFromDisk(s:Path.AbsolutePathFor(a:path))

    let newPath.cachedDisplayString = ""

    return newPath
endfunction

function! s:Path.Slash()
    return '/'
endfunction

" Invoke the vim resolve() function and return the result
" This is necessary because in some versions of vim resolve() removes trailing
" slashes while in other versions it doesn't.  This always removes the trailing
" slash
function! s:Path.Resolve(path)
    let tmp = resolve(a:path)
    return tmp =~# '.\+/$' ? substitute(tmp, '/$', '', '') : tmp
endfunction

function! s:Path.readInfoFromDisk(fullpath)
    let fullpath = a:fullpath

    if getftype(fullpath) ==# "fifo"
        throw "NERDTree.InvalidFiletypeError: Cant handle FIFO files: " . a:fullpath
    endif

    let self.pathSegments = filter(split(fullpath, '/'), '!empty(v:val)')

    let self.isReadOnly = 0
    if isdirectory(a:fullpath)
        let self.isDirectory = 1
    elseif filereadable(a:fullpath)
        let self.isDirectory = 0
        let self.isReadOnly = filewritable(a:fullpath) ==# 0
    else
        throw "NERDTree.InvalidArgumentsError: Invalid path = " . a:fullpath
    endif

    let self.isExecutable = 0
    if !self.isDirectory
        let self.isExecutable = getfperm(a:fullpath) =~# 'x'
    endif

    "grab the last part of the path (minus the trailing slash)
    let lastPathComponent = self.getLastPathComponent(0)

    "get the path to the new node with the parent dir fully resolved
    let hardPath = s:Path.Resolve(self.strTrunk()) . '/' . lastPathComponent

    "if  the last part of the path is a symlink then flag it as such
    let self.isSymLink = (s:Path.Resolve(hardPath) != hardPath)
    if self.isSymLink
        let self.symLinkDest = s:Path.Resolve(fullpath)

        "if the link is a dir then slap a / on the end of its dest
        if isdirectory(self.symLinkDest)

            "we always wanna treat MS windows shortcuts as files for
            "simplicity
            if hardPath !~# '\.lnk$'
                let self.symLinkDest = self.symLinkDest . '/'
            endif
        endif
    endif
endfunction

function! s:Path.refresh(nerdtree)
    call self.readInfoFromDisk(self.str())
    call self.cacheDisplayString()
endfunction

function! s:Path.refreshFlags(nerdtree)
    call self.cacheDisplayString()
endfunction

" Renames this node on the filesystem
function! s:Path.rename(newPath)
    if a:newPath ==# ''
        throw "NERDTree.InvalidArgumentsError: Invalid newPath for renaming = ". a:newPath
    endif

    let success =  rename(self.str(), a:newPath)
    if success != 0
        throw "NERDTree.PathRenameError: Could not rename: '" . self.str() . "'" . 'to:' . a:newPath
    endif
    call self.readInfoFromDisk(a:newPath)
endfunction

" Return a string representation of this Path object.
"
" Args:
" This function takes a single dictionary (optional) with keys and values that
" specify how the returned pathname should be formatted.
"
" The dictionary may have the following keys:
"  'format'
"  'escape'
"  'truncateTo'
"
" The 'format' key may have a value of:
"  'Cd' - a string to be used with ":cd" and similar commands
"  'Edit' - a string to be used with ":edit" and similar commands
"  'UI' - a string to be displayed in the NERDTree user interface
"
" The 'escape' key, if specified, will cause the output to be escaped with
" Vim's internal "shellescape()" function.
"
" The 'truncateTo' key shortens the length of the path to that given by the
" value associated with 'truncateTo'. A '<' is prepended.
function! s:Path.str(...)
    let options = a:0 ? a:1 : {}
    let toReturn = ""

    if has_key(options, 'format')
        let format = options['format']
        if has_key(self, '_strFor' . format)
            exec 'let toReturn = self._strFor' . format . '()'
        else
            throw 'NERDTree.UnknownFormatError: unknown format "'. format .'"'
        endif
    else
        let toReturn = self._str()
    endif

    if has_key(options, 'escape') && options['escape'] == 1
        let toReturn = shellescape(toReturn)
    endif

    if has_key(options, 'truncateTo')
        let limit = options['truncateTo']
        if len(toReturn) > limit-1
            let toReturn = toReturn[(len(toReturn)-limit+1):]
            if len(split(toReturn, '/')) > 1
                let toReturn = '</' . join(split(toReturn, '/')[1:], '/') . '/'
            else
                let toReturn = '<' . toReturn
            endif
        endif
    endif

    return toReturn
endfunction

function! s:Path._strForUI()
    let toReturn = '/' . join(self.pathSegments, '/')
    if self.isDirectory && toReturn != '/'
        let toReturn  = toReturn . '/'
    endif
    return toReturn
endfunction

" Return a string representation of this Path that is suitable for use as an
" argument to Vim's internal ":cd" command.
function! s:Path._strForCd()
    return fnameescape(self.str())
endfunction

" Return a string representation of this Path that is suitable for use as an
" argument to Vim's internal ":edit" command.
function! s:Path._strForEdit()

    " Make the path relative to the current working directory, if possible.
    let l:result = fnamemodify(self.str(), ':.')

    let l:result = fnameescape(l:result)

    if empty(l:result)
        let l:result = '.'
    endif

    return l:result
endfunction

function! s:Path._strForGlob()
    let lead = s:Path.Slash()

    let toReturn = lead . join(self.pathSegments, s:Path.Slash())
    let toReturn = escape(toReturn, self._escChars())

    return toReturn
endfunction

" Return the absolute pathname associated with this Path object.
function! s:Path._str()
    let l:separator = s:Path.Slash()
    let l:leader = l:separator

    return l:leader . join(self.pathSegments, l:separator)
endfunction

" Gets the path without the last segment on the end.
function! s:Path.strTrunk()
    return '/' . join(self.pathSegments[0:-2], '/')
endfunction
