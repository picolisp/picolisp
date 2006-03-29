" 16jan06abu
" (c) Software Lab. Alexander Burger

syn match   Comment           /#.*$/

syn region  TransientSymbol   start=/"/hs=s+1  end=/"/he=e-1  skip=/\\\\\|\\"/
highlight   TransientSymbol   term=underline cterm=underline gui=underline
