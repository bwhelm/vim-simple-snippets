scriptencoding utf-8
" vim: set fdm=marker foldlevel=0:
" ============================================================================
" Simple (Recursive) Snippets
" ============================================================================

" Mapping. Will return <C-n> if the pop-up menu is visible, otherwise will
" call the snippet function (after using '<C-]>' to trigger abbreviation
" completion.
inoremap <silent><expr> <Plug>simpleSnippetTrigger pumvisible() ? "\<C-n>" : "<C-]><C-r>=simplesnippets#RecursiveSnippetsHandler()<CR>"
