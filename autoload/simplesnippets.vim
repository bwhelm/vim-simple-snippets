" ============================================================================ }}}
" Simple (Recursive) Snippets {{{1
" ============================================================================
" Note: format of entries in this list is 'key': [length of characters to
" compare, length of key in chars, 'lhs', 'rhs', 'next']. Keys can be regex,
" so need to specify the numbers. (The regex should always end in `$` so that
" matches with longer numbers of characters aren't made. Starting with `.*`
" rather than just `.` will catch matches at the start of lines.) If 'rhs' is
" empty, there is no need to hit `<Tab>` to get out of snippet. Finally,
" 'next' is there to jump to a next snippet automatically.
"
" Change this to just a list: [key, length to compare, length of key, lhs,
" rhs, next]. Then extract the key using filter.

if !exists('g:SimpleSnippetsList')
    let g:SimpleSnippetsList = {}
endif

function! s:RestoreMapping(mapDict, key, mode) abort  "{{{1
    " Restores mapping saved in mapDict
    try
        execute a:mode . 'unmap <buffer>' a:key
    catch /E31/
    endtry
    if !empty(a:mapDict)
        execute (a:mapDict.noremap ? a:mapDict.mode . 'noremap' : a:mapDict.mode .'map') .
            \ (a:mapDict.buffer ? ' <buffer>' : '') .
            \ (a:mapDict.expr ? ' <expr>' : '') .
            \ (a:mapDict.nowait ? ' <nowait>' : '') .
            \ (a:mapDict.silent ? ' <silent>' : '') .
            \ ' ' . a:mapDict.lhs .
            \ ' ' . a:mapDict.rhs
    endif
endfunction

function! simplesnippets#DeleteSimpleSnippet() abort
    if !exists('b:recursiveSnippetList')
        let b:recursiveSnippetList = []
    endif
    if b:recursiveSnippetList == []
        if exists('b:completion_bs_map')
            call <SID>RestoreMapping(b:completion_bs_map, "\<BS>", 'i')
            unlet b:completion_bs_map
            return "\<BS>"
        else
            iunmap <BS>
            return "\<BS>"
        endif
    else
        let l:line = getline('.')
        let l:cursor = col('.')
        let [l:key, l:id] = b:recursiveSnippetList[-1]
        let l:match = <SID>RetrieveMatchedKey(l:key, l:id)[0]
        let l:leftMatch = l:match[3]
        let l:rightMatch = l:match[4]
        let l:previousChars = l:line[l:cursor - 1 - len(l:leftMatch):l:cursor - 2]
        let l:nextChars = l:line[l:cursor - 1:l:cursor + len(l:rightMatch) - 2]
        if l:previousChars ==# l:leftMatch && l:nextChars ==# l:rightMatch
            call remove(b:recursiveSnippetList, -1)
            if len(b:recursiveSnippetList) == 0 && exists('b:completion_bs_map')
                call <SID>RestoreMapping(b:completion_bs_map, "\<BS>", 'i')
                unlet b:completion_bs_map
            endif
            execute 'return "' . repeat("\<BS>", len(l:leftMatch)) .
                        \ repeat("\<DEL>", len(l:rightMatch)) . '"'
        else
            return "\<BS>"
        endif
    endif
endfunction

function! s:RetrieveMatchedKey(key, id) abort
    return filter(copy(g:SimpleSnippetsList),
                \ 'v:val[0] ==# a:key && v:val[6] ==# a:id')
endfunction

function! s:InsertSnippet(matchList) abort
    let [l:key, l:compLength, l:keyLength, l:left, l:right, l:next, l:id]
                \ = a:matchList
    if l:right !=# ''
        let b:recursiveSnippetList += [[l:key, l:id]]
    endif
    let l:typed = repeat("\<BS>", l:keyLength)
    let l:typed .= l:left . l:right
    let l:typed .= repeat("\<Left>", len(l:right))
    let b:completion_bs_map = maparg('<BS>', 'i', 0, 1)
    inoremap <silent> <BS> <C-r>=simplesnippets#DeleteSimpleSnippet()<CR>
    return l:typed
endfunction

function! s:JumpOutOfSnippet(line, cursor) abort
    let [l:key, l:id] = b:recursiveSnippetList[-1]
    call remove(b:recursiveSnippetList, -1)
    let l:matchList = <SID>RetrieveMatchedKey(l:key, l:id)
    let [l:key, l:compLength, l:keyLength, l:left, l:right, l:next, l:id]
                    \ = l:matchList[0]
    let l:matchPos = match(a:line, escape(l:right, '$.*~\^['), a:cursor - 1)
    let l:typed = repeat("\<Right>", len(l:right) + l:matchPos - a:cursor + 1)
    if l:next !=# ''
        let l:matchList = <SID>RetrieveMatchedKey(l:next, l:id)
        let l:typed .= repeat(' ', len(l:next))
                    \ . <SID>InsertSnippet(l:matchList[0])
    endif
    if exists('b:completion_bs_map')
        call <SID>RestoreMapping(b:completion_bs_map, "\<BS>", 'i')
        unlet b:completion_bs_map
    endif
    return l:typed
endfunction

function! s:RecursiveSimpleSnippets() abort
    let l:line = getline('.')
    let l:cursor = getpos('.')[2]
    " Check for match of simple snippets
    let l:matchLength = l:cursor < 11 ? l:cursor : 11  " Assume max length of 10 chars for key
    let l:matchString = l:line[l:cursor - l:matchLength : l:cursor - 2]
    let l:matches = filter(copy(g:SimpleSnippetsList), 'l:matchString[max([0, l:matchLength - v:val[1] - 1]) : l:matchLength - 1] =~# v:val[0]')
    if len(l:matches) == 1
        let b:stopAutoComplete = 1
        return <SID>InsertSnippet(l:matches[0])
    elseif len(l:matches) > 1
        let l:idList = map(copy(l:matches), 'v:val[6]')
        for l:index in range(len(l:idList))
            let l:idList[l:index] = string(l:index + 1) . '. ' . l:idList[l:index]
        endfor
        let l:match = l:matches[inputlist(l:idList) - 1]
        let b:stopAutoComplete = 1
        return <SID>InsertSnippet(l:match)
    elseif len(b:recursiveSnippetList) > 0 
        " No match, so check if need to jump to end of snippet
        let b:stopAutoComplete = 1
        return <SID>JumpOutOfSnippet(l:line, l:cursor)
    endif
    return ''
endfunction

function! simplesnippets#RecursiveSnippetsHandler(type) abort
    " Want to use omni completion first. Solution is modeled after
    " <https://stackoverflow.com/questions/2136801/vim-keyword-complete-when-omni-complete-returns-nothing>
    if !exists('b:recursiveSnippetList')
        let b:recursiveSnippetList = []
    endif
    if !exists('b:stopAutoComplete')
        let b:stopAutoComplete = 0
    endif
    if pumvisible() && !b:stopAutoComplete
        if a:type ==# 'snippet'
            let b:stopAutoComplete = 1
        endif
        return "\<C-N>"
    endif
    let l:cursor = getpos('.')[2]
    let l:previous = getline('.')[l:cursor - 2]
    " Cases in which we return a <Tab>: prior space, empty (beginning of line)
    " or ':' (for description lists).
    if (l:previous =~# '\s' ||
            \ l:previous ==# '' ||
            \ (l:previous ==# ':' && len(b:recursiveSnippetList) == 0))
            \ && !b:stopAutoComplete
        let b:stopAutoComplete = 1
        return "\<Tab>"
    endif
    if a:type ==# 'omni' && !b:stopAutoComplete
        if !pumvisible() && !&omnifunc
            return "\<C-X>\<C-O>"
        endif
    elseif a:type ==# 'snippet' && !pumvisible() && !b:stopAutoComplete
        return <SID>RecursiveSimpleSnippets()
    endif
    let b:stopAutoComplete = 0
    return ''
endfunction

augroup RecursiveSimpleSnippets
    " I don't want b:recursiveSnippetList to get too big if it's not being
    " consumed. This zeros it out on save.
    autocmd!
    autocmd BufWrite *
                \ let b:recursiveSnippetList = [] |
                \ if exists('b:completion_bs_map') |
                \ call <SID>RestoreMapping(b:completion_bs_map, "\<BS>", 'n') |
                \ unlet b:completion_bs_map |
                \ endif
augroup END
