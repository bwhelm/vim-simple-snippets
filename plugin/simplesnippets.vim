scriptencoding utf-8
" vim: set fdm=marker foldlevel=0:
" ============================================================================
" Simple (Recursive) Snippets
" ============================================================================

inoremap <Plug>simpleSnippetTrigger <C-R>=simplesnippets#RecursiveSnippetsHandler('omni')<CR><C-R>=simplesnippets#RecursiveSnippetsHandler('snippet')<CR>
