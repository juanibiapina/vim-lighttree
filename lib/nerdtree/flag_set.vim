let s:FlagSet = {}
let g:NERDTreeFlagSet = s:FlagSet

function! s:FlagSet.addFlag(scope, flag)
    let flags = self._flagsForScope(a:scope)
    if index(flags, a:flag) == -1
        call add(flags, a:flag)
    end
endfunction

function! s:FlagSet.clearFlags(scope)
    let self._flags[a:scope] = []
endfunction

function! s:FlagSet._flagsForScope(scope)
    if !has_key(self._flags, a:scope)
        let self._flags[a:scope] = []
    endif
    return self._flags[a:scope]
endfunction

function! s:FlagSet.New()
    let newObj = copy(self)
    let newObj._flags = {}
    return newObj
endfunction

function! s:FlagSet.removeFlag(scope, flag)
    let flags = self._flagsForScope(a:scope)

    let i = index(flags, a:flag)
    if i >= 0
        call remove(flags, i)
    endif
endfunction

function! s:FlagSet.renderToString()
    let flagstring = ""
    for i in values(self._flags)
        let flagstring .= join(i)
    endfor

    if len(flagstring) == 0
        return ""
    endif

    return '[' . flagstring . ']'
endfunction
