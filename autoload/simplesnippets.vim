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
		let [l:key, l:next] = b:recursiveSnippetList[-1]
		let l:leftMatch = g:SimpleSnippetsList[l:key][2]
		let l:rightMatch = g:SimpleSnippetsList[l:key][3]
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

function! s:InsertSnippet(key) abort
	let [l:compLength, l:keyLength, l:left, l:right, l:next] =
				\ g:SimpleSnippetsList[a:key]
	if l:right !=# ''
		let b:recursiveSnippetList += [[a:key, l:next]]
	endif
	let l:typed = repeat("\<BS>", l:keyLength)
	let l:typed .= l:left . l:right
	let l:typed .= repeat("\<Left>", len(l:right))
	let b:completion_bs_map = maparg('<BS>', 'i', 0, 1)
	inoremap <BS> <C-r>=simplesnippets#DeleteSimpleSnippet()<CR>
	return l:typed
endfunction

function! s:JumpOutOfSnippet(line, cursor) abort
	let [l:key, l:next] = b:recursiveSnippetList[-1]
	call remove(b:recursiveSnippetList, -1)
	let [l:compLength, l:keyLength, l:left, l:right, l:next] =
				\ g:SimpleSnippetsList[l:key]
	let l:matchPos = match(a:line, escape(l:right, '$.*~\^['), a:cursor - 1)
	let l:typed = repeat("\<Right>", len(l:right) + l:matchPos - a:cursor + 1)
	if l:next !=# ''
		let l:typed .= repeat(' ', len(l:next)) . <SID>InsertSnippet(l:next)
	endif
	if exists('b:completion_bs_map')
		call <SID>RestoreMapping(b:completion_bs_map, "\<BS>", 'i')
		unlet b:completion_bs_map
	endif
	return l:typed
endfunction

function! simplesnippets#RecursiveSimpleSnippets() abort
	if !exists('b:recursiveSnippetList')
		let b:recursiveSnippetList = []
	endif
	let l:line = getline('.')
	let l:cursor = getpos('.')[2]
	let l:previous = l:line[l:cursor - 2]
	" Cases in which we return a <Tab>: prior space, empty (beginning of line)
	" or ':' (for description lists).
	if l:previous =~# '\s' || l:previous ==# '' || l:previous ==# ':'
		return "\<Tab>"
	endif
	" Check for match of simple snippets
	for l:key in keys(g:SimpleSnippetsList)
		let [l:compLength, l:keyLength, l:left, l:right, l:next] =
					\ g:SimpleSnippetsList[l:key]
		if l:cursor - l:compLength < 1
			let l:compLength -= 1
		endif
		let l:possMatch = l:line[l:cursor - l:compLength - 1:l:cursor - 2]
		if l:possMatch =~# l:key
			return <SID>InsertSnippet(l:key)
		endif
	endfor
	" No match, so check if need to jump to end of snippet
	if len(b:recursiveSnippetList) > 0
		return <SID>JumpOutOfSnippet(l:line, l:cursor)
	else  " Not finding shortcut, no nested snippet, so try omni-completion
		return "\<C-X>\<C-O>"
	endif
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
