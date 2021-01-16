scriptencoding utf-8

" require 7.4.1658 for v:vim_did_enter
if &compatible
      \ || !has('statusline')
      \ || !has('reltime')
      \ || v:version < 704
      \ || (v:version == 704 && !has('patch1658'))
      \ || exists('g:loaded_match_count_statusline')
  finish
endif
let g:loaded_match_count_statusline = v:true

" gdefault option inverts meaning of 'g' flag on patterns
if &gdefault
  let s:match_command = '%s//&/ne'
else
  let s:match_command = '%s//&/gne'
endif

" force disabling airline
let s:disable_airline = get(g:, 'match_count_disable_airline', v:false)

" force disabling statusline
let s:disable_statusline = get(g:, 'match_count_disable_statusline', v:false)

" max file size before automatically disabling
let s:max_file_size_in_bytes = get(g:, 'match_count_max_file_size_in_bytes', 10 * 1024 * 1024)

" cache timeout (so we don't drag during, e.g., incsearch)
let s:cache_timeout_in_seconds = get(g:, 'match_count_cache_timeout_in_seconds', 0.25)

" force short length display (just the count)
let s:short_display = get(g:, 'match_count_short_display', v:false)

" force medium length display
let s:medium_display = get(g:, 'match_count_medium_display', v:false)

" force long display (count along with pattern)
let s:long_display = get(g:, 'match_count_long_display', v:false)

let s:start = get(g:, 'match_count_start', '')

let s:end = get(g:, 'match_count_end', '')

" default sentinel values representing an unused cache
let s:unused_cache_values = {
      \   'pattern':      -1,
      \   'changedtick':  -1,
      \   'match_count':  -1,
      \   'last_updated': -1
      \ }

" return v:true if cache is stale, v:false if not
function! s:IsCacheStale(count_cache)
  " hit the cache the first time around so there's a brief window when
  " first searching for a pattern before we update the statusline
  if a:count_cache == s:unused_cache_values
    let a:count_cache.last_updated = reltime()
    return v:false
  endif

  let l:seconds = s:cache_timeout_in_seconds
  let l:micros = s:cache_timeout_in_seconds * 1000000

  try
    " not calling reltimefloat for perf reasons
    let l:time_elapsed = reltime(a:count_cache.last_updated)
    if type(l:time_elapsed) != 3          " error (treat as cache miss)
      return v:true
    elseif l:time_elapsed[0] > l:seconds  " cache miss (more than a second)
      return v:true
    elseif l:time_elapsed[1] > l:micros   " cache miss (less than a second)
      return v:true
    else                                  " cache hit
      return v:false
    endif
  catch                                   " error (treat as cache miss)
    return v:true
  endtry
endfunction

" use the cache and window width to construct the status string
function! s:PrintMatchCount(count_cache)
  if empty(@/)
    return ''
  elseif a:count_cache.match_count == -1
    return s:start . 'working...' . s:end
  else
    " try to adapt to window width (respecting forced display)
    if winwidth(0) >= 120 && !s:short_display && !s:medium_display
      return s:start . a:count_cache.match_count . ' matches of /' . a:count_cache.pattern . '/' . s:end
    elseif winwidth(0) < 120 && winwidth(0) >= 100 && !s:short_display && !s:long_display
      return s:start . a:count_cache.match_count . ' matches' . s:end
    elseif !s:long_display && !s:medium_display
      return s:start . a:count_cache.match_count . s:end
    endif
  endif
endfunction

" return v:true if file is too large to process, v:false if not
" (if match counting has been toggled on manually, we ignore file size)
function! s:IsLargeFile(force)
  if a:force
    return v:false
  else
    if getfsize(expand(@%)) >= s:max_file_size_in_bytes
      return v:true
    else
      return v:false
    endif
  endif
endfunction

" allow forcing on or off match-counting for a buffer (also allows
" overriding the file-size detection, hence the `force` variable)
function! s:ToggleMatchCounting()
  " define buffer variables if not already defined
  let b:match_count_force = get(b:, 'match_count_force', v:false)
  let b:match_count_enable = get(b:, 'match_count_enable', v:true)

  if b:match_count_force == v:false && b:match_count_enable == v:true
    let b:match_count_force = v:false
    let b:match_count_enable = v:false
    echom 'Match counting disabled for this buffer'
  elseif b:match_count_force == v:false && b:match_count_enable == v:false
    let b:match_count_force = v:true
    let b:match_count_enable = v:true
    echom 'Match counting enabled for this buffer'
  elseif b:match_count_force == v:true && b:match_count_enable == v:true
    let b:match_count_force = v:false
    let b:match_count_enable = v:false
    echom 'Match counting disabled for this buffer'
  else
    " this possibility shouldn't arise, but it's here for completeness
    let b:match_count_force = v:true
    let b:match_count_enable = v:true
    echom 'Match counting enabled for this buffer'
  endif

  redrawstatus!
endfunction

" most modes we don't actually need to update the statusline, but for
" a few, we do. this should help fix #1
function! s:IsAcceptableMode()
  let l:mode = mode()

  if mode ==# 'n' || mode ==? 'v' || mode ==# 'i' || mode ==# 'R' || mode ==# 'Rv' || mode ==? 's'
    return v:true
  else
    return v:false
  endif
endfunction

" calculate the match count
function! MatchCountStatusline()
  " don't bother executing until Vim has fully loaded
  if v:vim_did_enter == v:false
    return ''
  endif

  " don't update unless we're in a mode that matters
  if !s:IsAcceptableMode() | return '' | endif

  " define buffer variables if not already defined
  let b:match_count_force = get(b:, 'match_count_force', v:false)
  let b:match_count_enable = get(b:, 'match_count_enable', v:true)

  " do nothing if disabled in this buffer
  if b:match_count_enable == v:false | return '' | endif

  if s:IsLargeFile(b:match_count_force)
    " this allows the force/match variables to match one another for
    " large files so that you can toggle back on right away instead of
    " needing to toggle off first
    if b:match_count_force == v:false && b:match_count_enable == v:true
      let b:match_count_enable = v:false
    endif
    return ''
  endif

  let b:count_cache = get(b:, 'count_cache', copy(s:unused_cache_values))

  " use the cache no matter what if it hasn't gone stale
  if !s:IsCacheStale(b:count_cache)
    return s:PrintMatchCount(b:count_cache)
  endif

  " check if cached match count is still valid before recounting matches
  if b:count_cache.pattern ==# @/ && b:count_cache.changedtick == b:changedtick
    return s:PrintMatchCount(b:count_cache)
  endif

  " don't count matches that aren't being searched for
  if empty(@/)
    let b:count_cache.pattern     = ''
    let b:count_cache.match_count = 0
    let b:count_cache.changedtick = b:changedtick
    let b:count_cache.last_updated = reltime()
  else
    try
      " freeze the view in place
      let l:view = winsaveview()

      " turn off hlsearch
      if has('extra_search')
        let l:hlsearch = v:hlsearch
        if l:hlsearch
          let v:hlsearch = v:false
        endif
      endif

      " disable autocmds
      if has('autocmd')
        let l:events_ignored = &eventignore
        set eventignore =
      endif

      " this trick counts the matches (see :help count-items)
      redir => l:match_output
      silent! execute s:match_command
      redir END

      if empty(l:match_output) || l:match_output =~ 'error'
        let l:match_count = 0
      else
        let l:match_count = split(l:match_output)[0]
      endif

      let b:count_cache.pattern      = @/
      let b:count_cache.match_count  = l:match_count
      let b:count_cache.changedtick  = b:changedtick
      let b:count_cache.last_updated = reltime()
    catch
      " the actual search is `silent!` and should suppress most errors,
      " but in case any slip through, they reach here
      echom 'Caught exception while counting matches: "' .
            \ v:exception . '" from ' . v:throwpoint .
            \ ' with match output: "' . l:match_output . '"'

      " if there's an error, let's pretend we don't see anything
      let b:count_cache.pattern      = @/
      let b:count_cache.match_count  = 0
      let b:count_cache.changedtick  = b:changedtick
      let b:count_cache.last_updated = reltime()
    finally
      if has('autocmd')
        let &eventignore = l:events_ignored
      endif

      call winrestview(l:view)

      if has('extra_search')
        let l:hlsearch = v:hlsearch
        if l:hlsearch
          let v:hlsearch = 0
        endif
      endif
    endtry
  endif

  return s:PrintMatchCount(b:count_cache)
endfunction

if exists('g:loaded_airline') && !s:disable_airline
  call airline#parts#define('match_count', { 'function': 'MatchCountStatusline' })
  let g:airline_section_b = airline#section#create(['match_count'])
elseif !s:disable_statusline
  " add to statusline if it's not already added manually and if airline
  " doesn't exist
  if &statusline !~ 'MatchCountStatusline'
    " no space after `=` on the next line
    set laststatus=2
    set ruler
    let &statusline = '%!MatchCountStatusline() ' . &statusline
  endif
endif

function! s:CountMatchesOnDemand()
  let l:match_count_was_enabled = get(b:, 'match_count_enable')
  let b:match_count_enable      = v:true
  let l:output                  = MatchCountStatusline()
  let b:match_count_enable      = l:match_count_was_enabled

  return l:output
endfunction

command! -nargs=0 ToggleMatchCounting call <SID>ToggleMatchCounting()
command! -nargs=0 CountMatches echo <SID>CountMatchesOnDemand()
