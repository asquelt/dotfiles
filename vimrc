execute pathogen#infect()

colorscheme peachpuff

set tabstop=4
set encoding=utf-8
set fileencoding=utf-8

set list
set listchars=tab:»·,trail:¶

set expandtab
set shiftwidth=4
set softtabstop=4

" http://stackoverflow.com/questions/16902317/vim-slow-with-ruby-syntax-highlighting
set ttyfast
set lazyredraw
"set re=1

filetype indent on
set ai
set si

map <F9> :Gblame <CR> :wincmd l <CR>
map <F10> :Gedit <CR>
map <F12> :set paste! <CR>

command Abort cq

"define 3 custom highlight groups
hi User1 ctermbg=green ctermfg=red   guibg=green guifg=red
hi User2 ctermbg=red   ctermfg=blue  guibg=red   guifg=blue
hi User3 ctermbg=blue  ctermfg=green guibg=blue  guifg=green

set statusline=
"set statusline+=%t       "tail of the filename
set statusline+=%f
set statusline+=%2*  "switch to User2 highlight
set statusline+=%y      "filetype
set statusline+=%3*  "switch to User3 highlight
set statusline+=[%{strlen(&fenc)?&fenc:'none'}, "file encoding
set statusline+=%{&ff}] "file format
set statusline+=%*       "switch back to normal statusline highlight
set statusline+=%h      "help file flag
set statusline+=%m      "modified flag
set statusline+=%r      "read only flag
set statusline+=%1*  "switch to User1 highlight
set statusline+=%{exists('g:loaded_fugitive')?fugitive#statusline():''}
set statusline+=%*       "switch back to normal statusline highlight
set statusline+=%=      "left/right separator
"set statusline+=\ [%03b][0x%02B]\               " ASCII and byte code under cursor
set statusline+=[0x%02B]              " ASCII and byte code under cursor
set statusline+=%3c,     "cursor column
set statusline+=%l/%L   "cursor line/total lines
set statusline+=\ %2P    "percent through file

" always display status line
:set laststatus=2

" fugitive vim
autocmd QuickFixCmdPost *grep* cwindow

" http://stackoverflow.com/questions/9065941/how-can-i-change-vim-status-line-colour
function! InsertStatuslineColor(mode)
  if a:mode == 'i'
    hi statusline guibg=Green ctermfg=green guifg=Black ctermbg=black
  elseif a:mode == 'r'
    hi statusline guibg=DarkRed ctermfg=red guifg=Black ctermbg=black
  else
    hi statusline guibg=Cyan ctermfg=cyan guifg=Black ctermbg=black
  endif
endfunction

au InsertEnter * call InsertStatuslineColor(v:insertmode)
au InsertLeave * hi statusline guibg=DarkGrey ctermfg=8 guifg=White ctermbg=15

" default the statusline when entering Vim
hi statusline guibg=DarkGrey ctermfg=8 guifg=White ctermbg=15

" http://western-skies.blogspot.com/2013/05/ctags-for-puppet-three-previously.html
set iskeyword=-,:,@,48-57,_,192-255

" Tell vim to remember certain things when we exit
"  '10000 :  marks will be remembered for up to 10 previously edited files
"  "100   :  will save up to 100 lines for each register
"  :50    :  up to 20 lines of command-line history will be remembered
"  %      :  saves and restores the buffer list
"  n...   :  where to save the viminfo files
set viminfo='10000,\"100,:50,%,n~/.viminfo

function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END

set backup
