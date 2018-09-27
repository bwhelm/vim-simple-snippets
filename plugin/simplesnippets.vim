scriptencoding utf-8
" vim: set fdm=marker foldlevel=0:
" ============================================================================
" Simple (Recursive) Snippets
" ============================================================================

" Mapping. '<C-]>' will trigger abbreviation completion.
inoremap <silent> <Plug>simpleSnippetTrigger <C-]><C-R>=simplesnippets#RecursiveSnippetsHandler('snippet')<CR><C-R>=simplesnippets#RecursiveSnippetsHandler('omni')<CR>
