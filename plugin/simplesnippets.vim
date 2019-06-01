scriptencoding utf-8
" vim: set fdm=marker:
" ============================================================================
" Simple (Recursive) Snippets
" ============================================================================

" Mapping.
inoremap <silent> <Plug>simpleSnippetTrigger
                \ <C-]><C-r>=simplesnippets#RecursiveSnippetsHandler()<CR>
