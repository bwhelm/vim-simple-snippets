# vim-simple-snippets

Recursive simple snippets for vim

Provides *simple* functionality for snippets, but allows snippets to be activated inside other snippets, with `<Tab>` jumping out of the scope of each snippet one-by-one.

User must define `g:SimpleSnippetsList`, a dictionary that uses the snippet
trigger for its key, whose value is a list: [length of characters to compare,
length of key in chars, 'lhs', 'rhs', 'next']. Keys can be regex, so the number
of characters need to be specified (which won't in general be the same as the
number of characters in the regex). (The regex should always end in `$` so that
matches with longer numbers of characters aren't made. Starting with `.*\<`
rather than just `.\<` will catch matches at beginnings of words that occur at
the start of lines.) If 'rhs' is empty, there is no need to hit `<Tab>` to get
out of snippet. Finally, 'next' is there to jump to a next snippet
automatically.

Here's an example set-up for pandoc-flavored markdown:

	let g:SimpleSnippetsList = {
			\ '88':      [2, 2, '**',            '**',            ''],
			\ '8':       [1, 1, '*',             '*',             ''],
			\ '-':       [1, 1, '---',           '---',           ''],
			\ 'fn':      [2, 2, '^[',            ']',             ''],
			\ '.*\<li$': [3, 2, '[',             ']',             'li-1'],
			\ 'li-1':    [4, 4, '(',             ')',             'li-2'],
			\ 'li-2':    [4, 4, '{',             '}',             ''],
			\ '.*\<im$': [3, 2, '![',            ']',             'li-1'],
			\ '.*\<hr$': [3, 2, repeat('-', 76), '',              ''],
			\ }

User must provide a mapping to `<Plug>simpleSnippetTrigger`, such as the
following:

	imap <Tab> <PlugsimpleSnippetTrigger

or, to also use `<Tab>` to move forward in pop-up menus:

	imap <expr> <Tab> pumvisible() ? "\<C-P>" : "\<Plug>simpleSnippetTrigger"
