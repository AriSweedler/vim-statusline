" Ari Sweedler

" {{{ Init
" Always have a statusline (not just to show a divide between windows).
set laststatus=2

" Default to inactive statuslines. Let the autocmd activate it
set statusline=%!statusline#inactive()
set statusline=%!statusline#active()

" {{{ Autocommands
augroup Statusline
  autocmd!
  autocmd WinLeave,BufLeave * setlocal statusline=%!statusline#inactive()
  autocmd WinEnter,BufEnter * setlocal statusline=%!statusline#active()
  "
  "recalculate the tab warning flag when idle and after writing
  autocmd cursorhold,bufwritepost * unlet! b:statusline_errors
augroup END
" }}}

" Init variables to defaults
let b:statusline_mode_highlight = 'StatuslineModeNormal'
let b:statusline_mode_text = 'NORMAL'
let b:statusline_modified_highlight = 'StatuslineUnmodified'
" }}}
" {{{ Mode map
let s:modes ={
      \ 'n'  : ['StatuslineModeNormal', 'NORMAL'],
      \ 'i'  : ['StatuslineModeInsert', 'INSERT'],
      \ 'v'  : ['StatuslineModeVisual', 'VISUAL'],
      \ 'V'  : ['StatuslineModeVLine', 'V-LINE'],
      \ '' : ['StatuslineModeVBlock', 'VBLOCK'],
      \ 'c'  : ['StatuslineModeCommand', 'CMMAND'],
      \ '-'  : ['StatuslineModeOther', '------']}
" }}}
function! statusline#active() abort " {{{
  let s = ''
  let s .= statusline#mode(1)
  let s .= statusline#gitinfo()
  let s .= statusline#filename(1)
  let s .= statusline#mod_divider()
  let s .= statusline#typeinfo(1)
  let s .= statusline#cursorinfo()
  let s .= statusline#spelling()
  let s .= statusline#errors()
  return s
endfunction
" }}}
function! statusline#inactive() abort " {{{
  let s  = statusline#color('StatuslineInactiveBackground', ' ..')
  let s .= statusline#filename(0)
  let s .= statusline#color('StatuslineInactiveBackground', '..%=..')
  let s .= statusline#typeinfo(0)
  let s .= statusline#color('StatuslineInactiveBackground', '.. ')
  return s
endfunction
" }}}
function! statusline#color(highlight_group, text) abort " {{{
  return '%#' . a:highlight_group . '#' . a:text . '%*'
endfunction " }}}
function! statusline#spelling() abort " {{{
  if &spell
    return statusline#color('StatuslineSpelling', ' spell: [' . &spelllang . '] ')
  endif
  return ''
endfunction " }}}
function! statusline#filename(active) abort " {{{
  if a:active
    return statusline#color('StatuslineFilename', ' %f ')
  else
    return statusline#color('StatuslineInactiveInfo', ' %F ')
  endif
endfunction " }}}
function! statusline#mod_divider() abort " {{{
  " Display/highlight the modified flag & "separation point"
  let mod = &modified ? 'StatuslineModified' : 'StatuslineUnmodified'
  return statusline#color(l:mod, ' %m %=')
endfunction " }}}
function! statusline#gitbranch() abort " {{{
  " Only call this function when active
  if exists('g:loaded_fugitive') && &modifiable
    return statusline#color(b:statusline_mode_highlight . 'Reverse', ' ' . fugitive#head() . ' ')
  endif
  return ' ~no git~ '
endfunction " }}}
function! statusline#gitchanges() abort " {{{
  " Only call this function when active
  if exists('g:loaded_gitgutter') && &modifiable
    let [added,modified,removed] = GitGutterGetHunkSummary()
    let s = ''
    let s .= statusline#color('StatuslineGitGutterAdd', '+' . added)
    let s .= statusline#color('StatuslineGitGutterChange', '~' . modified)
    let s .= statusline#color('StatuslineGitGutterDelete', '-' . removed)
    return s
  endif
  return ''
endfunction " }}}
function! statusline#gitdotfiles() abort " {{{
  " Only call this function when active
  " Only useful if you follow 'https://www.atlassian.com/git/tutorials/dotfiles
  if exists('g:loaded_gitgutter') && &modifiable && g:gitgutter_git_executable == "git"
    return ''
  endif
  return statusline#color(b:statusline_mode_highlight . 'Reverse', ' [DOTFILES]')
endfunction " }}}
function! statusline#gitinfo() abort " {{{
  " Only call this function when active
  " TODO make this just '===' when no git repo. FIX THIS ! :(
  if exists('g:loaded_fugitive') && &modifiable
    let s = ''
    let s .= statusline#color(b:statusline_mode_highlight . 'Reverse', ' ==')
    let s .= statusline#gitbranch()
    let s .= statusline#gitchanges()
    let s .= statusline#gitdotfiles()
    let s .= statusline#color(b:statusline_mode_highlight . 'Reverse', ' == ')
    return s
  endif
  return ''
endfunction " }}}
function! statusline#typeinfo(active) abort " {{{
  if empty(&filetype)
    return ''
  endif

  if a:active
    return statusline#color('StatuslineFiletype', ' %y ')
  else
    return statusline#color('StatuslineInactiveInfo', ' %y ')
  endif
endfunction " }}}
function! statusline#cursorinfo() abort " {{{
  return statusline#color(b:statusline_mode_highlight, ' %l/%L c%c ')
endfunction " }}}
function! statusline#errors() abort " {{{
  " Cache statusline_errors
  if !exists("b:statusline_errors")
    let s = ''

    " Check for trailing whitespace
    if &modifiable && search('\s$', 'nw')
      let s .= '[TRAILING WHITESPACE]'
    endif

    " Check for mixed intent
    if &modifiable && search('^\t', 'nw', line('.') + 1) && search('^  [^\s]', 'nw')
      let s .= '[MIXED INDENT]'
    endif

    if empty(s)
      let b:statusline_errors = s
    else
      let s = ' ' . s . ' '
      let b:statusline_errors = statusline#color('ErrorMsg', s)
    endif
  endif
  return b:statusline_errors
endfunction " }}}
function! statusline#mode(active) abort " {{{
  let m = get(s:modes, mode(), '-')
  let b:statusline_mode_highlight = m[0]
  let b:statusline_mode_text = m[1]
  return statusline#color(b:statusline_mode_highlight, ' ' . b:statusline_mode_text . ' ')
endfunction " }}}
" {{{ Colors
highlight StatuslineFilename ctermfg=230 ctermbg=53
highlight StatuslineUnmodified ctermfg=7 ctermbg=234
highlight StatuslineModified ctermfg=195 ctermbg=17
highlight StatuslineGit ctermfg=44 ctermbg=16
highlight StatuslineFiletype ctermfg=16 ctermbg=102
highlight StatuslineSpelling ctermfg=24 ctermbg=236
highlight StatuslineInactiveInfo ctermfg=249 ctermbg=235
highlight StatuslineInactiveBackground ctermfg=239 ctermbg=234
" {{{ Modes
highlight StatuslineModeNormal ctermfg=0 ctermbg=44
highlight StatuslineModeInsert ctermfg=0 ctermbg=41
highlight StatuslineModeVisual ctermfg=0 ctermbg=208
highlight StatuslineModeVLine ctermfg=0 ctermbg=208
highlight StatuslineModeVBlock ctermfg=0 ctermbg=208
highlight StatuslineModeCommand ctermfg=0 ctermbg=184
highlight StatuslineModeOther ctermfg=3 ctermbg=11
" }}}
" {{{ Reverse Modes
highlight StatuslineModeNormalReverse cterm=bold ctermfg=44 ctermbg=0
highlight StatuslineModeInsertReverse cterm=bold ctermfg=41 ctermbg=0
highlight StatuslineModeVisualReverse cterm=bold ctermfg=208 ctermbg=0
highlight StatuslineModeVLineReverse cterm=bold ctermfg=208 ctermbg=0
highlight StatuslineModeVBlockReverse cterm=bold ctermfg=208 ctermbg=0
highlight StatuslineModeCommandReverse cterm=bold ctermfg=184 ctermbg=0
highlight StatuslineModeOtherReverse cterm=bold ctermfg=208 ctermbg=0
" }}}
" {{{ GitGutter
highlight StatuslineGitGutterAdd term=bold ctermfg=34 ctermbg=0
highlight StatuslineGitGutterChange term=bold ctermfg=142 ctermbg=0
highlight StatuslineGitGutterDelete term=bold ctermfg=1 ctermbg=0
" }}}
" }}}
