" Picolisp plug-in file
" Language: Picolisp 
" Maintainer: Pedro Gomes
" Last Change: 2014 Aug 07

" Need to have this two utilities in /usr/bin or within the system PATH
map , !}pilIndent<CR>
map <F11> %mz%:execute ".,'z!pilPretty" col(".")<CR>
