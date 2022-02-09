" Ari Sweedler

" {{{ Init
" Always have a statusline (not just to show a divide between windows).
set laststatus=2

" Default to inactive statuslines. Let the autocmd activate it
set statusline=%!statusline#inactive()
set statusline=%!statusline#active()

set noshowmode

" {{{ Autocommands
augroup Statusline
  autocmd!

  " Statusline setting
  autocmd WinLeave,BufLeave * setlocal statusline=%!statusline#inactive()
  autocmd WinEnter,BufEnter * setlocal statusline=%!statusline#active()

  " Branch cache
  " TODO maybe have this just be lazy-eval'd instead of cached. To do this,
  " add 'cursorhold' to the unset | set autocmd to do this. Seems a bit too
  " expensive though
  autocmd WinEnter,BufEnter * call statusline#cache_git_branch()
  autocmd WinLeave,BufLeave * call statusline#uncache_git_branch()
  autocmd bufwritepost * call statusline#uncache_git_branch() | call statusline#cache_git_branch()

  " Error cache
  " Recalculate the tab warning flag when idle and after writing
  autocmd cursorhold,bufwritepost * unlet! b:statusline_errors
augroup END
" }}}

" Init variables to defaults
let b:statusline_mode_highlight = 'StatuslineModeNormal'
let b:statusline_mode_text = 'NORMAL'

" Refresh the statusline (needs to happen when a Session is restored)
command ReloadStatusline runtime START statusline.vim
" }}}
" {{{ Mode map
let s:modes ={
      \ 'n'  : ['StatuslineModeNormal', 'NORMAL'],
      \ 'i'  : ['StatuslineModeInsert', 'INSERT'],
      \ 'v'  : ['StatuslineModeVisual', 'VISUAL'],
      \ 'V'  : ['StatuslineModeVLine', 'V-LINE'],
      \ '' : ['StatuslineModeVBlock', 'VBLOCK'],
      \ 'c'  : ['StatuslineModeOther', 'CMMAND'],
      \ 'R'  : ['StatuslineModeOther', 'REPLACE'],
      \ '-'  : ['StatuslineModeNull', '------']}
" }}}
function! statusline#active() abort " {{{
  " First thing we do every tick is ensure we have the right gitgutter
  " command. This has nothing to do with the statusline, other than it, too,
  " controls the colorful border I like having on my screen.
  call lib#update_gitgutter_dotfile()

  let s = ''
  let s .= statusline#mode(1)
  let s .= statusline#gitinfo()
  let s .= statusline#filename(1)
  let s .= statusline#mod_divider()
  let s .= statusline#pokeme()
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
function! statusline#uncache_git_branch() abort " {{{
  if exists('b:statusline_branch')
    unlet b:statusline_branch
  endif
endfunction " }}}
function! statusline#cache_git_branch() abort " {{{
  " No need to figure this out twice
  if exists('b:statusline_branch')
    return
  endif

  " TODO be rigorous here (have it work with dotfiles)
  " I'm lazy, this is good enough. If fugitive can find our repo, I don't need
  " to do any more work.
  if fugitive#head() != ''
    let b:statusline_branch = fugitive#head()
    return
  endif

  let b:statusline_branch = ''
  return
endfunction " }}}
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
function! statusline#gitchanges() abort " {{{
  let [added,modified,removed] = GitGutterGetHunkSummary()
  let s = ''
  let s .= statusline#color('StatuslineGitGutterAdd', '+' . added)
  let s .= statusline#color('StatuslineGitGutterChange', '~' . modified)
  let s .= statusline#color('StatuslineGitGutterDelete', '-' . removed)
  let s .= statusline#color(b:statusline_mode_highlight . 'Reverse', ' ')
  return s
endfunction " }}}
function! statusline#gitinfo() abort " {{{
  if !exists('b:statusline_branch')
    let b:statusline_branch = ''
  endif

  let dotfiles_tag = lib#in_dotfiles() ? '[DOTFILES] ' : ''
  if b:statusline_branch == ''
    return statusline#color(b:statusline_mode_highlight . 'Reverse', ' ~===~ ' . l:dotfiles_tag)
  elseif exists('g:loaded_gitgutter') && &modifiable
    let s = ''
    let s .= statusline#color(b:statusline_mode_highlight . 'Reverse', ' == ' . b:statusline_branch . ' ')
    let s .= statusline#gitchanges()
    let s .= statusline#color(b:statusline_mode_highlight . 'Reverse', l:dotfiles_tag . '== ')
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
function! statusline#pokeme() abort " {{{
  " Extra (optional/stateful) information. Lives on the right side of the
  " statusline. Each clause is called a "poke"
  let poker = ''

  " 1) Check for the k-mark. If it's active, then we're trying to make a link
  let k_mark = col("'k")
  if k_mark != 0
    let poker .= statusline#color(b:statusline_mode_highlight, ' K-mark active ')
  endif

  " 2) Check for g:ari_debug value, display it if possible (ToggleDebugSyntax,
  " for example)
  if exists("g:ari_debug")
    for [k, v] in items(g:ari_debug)
      if v == 'inactive' | continue | endif
      let poker .= statusline#color('StatuslinePoke1', ' Debug '.k.' ')
    endfor
  endif

  " 3) Check for 'paste'
  if (&paste == 1)
    let poker .= statusline#color('StatuslinePoke1', ' [paste] ')
  endif

  " 4) Check for OTHER STATE (future expansion :3)

  return poker
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
highlight StatuslineInactiveInfo ctermfg=249 ctermbg=69
"highlight StatuslineInactiveBackground ctermfg=239 ctermbg=234
highlight StatuslineInactiveBackground ctermfg=239 ctermbg=195
" {{{ Modes
highlight StatuslineModeNormal ctermfg=0 ctermbg=44
highlight StatuslineModeInsert ctermfg=0 ctermbg=41
highlight StatuslineModeVisual ctermfg=0 ctermbg=208
highlight StatuslineModeVLine ctermfg=0 ctermbg=208
highlight StatuslineModeVBlock ctermfg=0 ctermbg=208
highlight StatuslineModeOther ctermfg=0 ctermbg=184
highlight StatuslinePoke1 ctermfg=2 ctermbg=0
highlight StatuslineModeNull ctermfg=3 ctermbg=11
" }}}
" {{{ Reverse Modes
highlight StatuslineModeNormalReverse cterm=bold ctermfg=44 ctermbg=0
highlight StatuslineModeInsertReverse cterm=bold ctermfg=41 ctermbg=0
highlight StatuslineModeVisualReverse cterm=bold ctermfg=208 ctermbg=0
highlight StatuslineModeVLineReverse cterm=bold ctermfg=208 ctermbg=0
highlight StatuslineModeVBlockReverse cterm=bold ctermfg=208 ctermbg=0
highlight StatuslineModeOtherReverse cterm=bold ctermfg=184 ctermbg=0
highlight StatuslineModeNullReverse cterm=bold ctermfg=208 ctermbg=0
" }}}
" {{{ GitGutter
highlight StatuslineGitGutterAdd term=bold ctermfg=34 ctermbg=0
highlight StatuslineGitGutterChange term=bold ctermfg=142 ctermbg=0
highlight StatuslineGitGutterDelete term=bold ctermfg=1 ctermbg=0
" }}}
" }}}
