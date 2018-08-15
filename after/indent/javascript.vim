" Description: Vim lit-html indent file
" Language: JavaScript
" Maintainer: Jon Smithers <mail@jonsmithers.link>

" Save the current JavaScript indentexpr.
let b:litHtmlOriginalIndentExpression = &indentexpr

" import xml indent
if exists('b:did_indent')
  let s:did_indent=b:did_indent
  unlet b:did_indent
endif
exe 'runtime! indent/html.vim'
if exists('s:did_indent')
  let b:did_indent=s:did_indent
endif

" import css indent
if exists('b:did_indent')
  let s:did_indent=b:did_indent
  unlet b:did_indent
endif
exe 'runtime! indent/css.vim'
if exists('s:did_indent')
  let b:did_indent=s:did_indent
endif

setlocal indentexpr=ComputeLitHtmlIndent()

" JS indentkeys
setlocal indentkeys=0{,0},0),0],0\,,!^F,o,O,e
" XML indentkeys
setlocal indentkeys+=*<Return>,<>>,<<>,/
" lit-html indentkeys
setlocal indentkeys+=`

" Multiline end tag regex (line beginning with '>' or '/>')
let s:endtag = '^\s*\/\?>\s*;\='

" Get syntax stack at StartOfLine
fu! VHTL_SynSOL(lnum)
  let l:col = match(getline(line('.')), '\S')
  if (l:col == -1)
    return []
  endif
  return map(synstack(a:lnum, l:col+1), "synIDattr(v:val, 'name')")
endfu

" Get syntax stack at EndOfLine
fu! VHTL_SynEOL(lnum)
  if (a:lnum < 1)
    return []
  endif
  let l:col = strlen(getline(a:lnum))
  return map(synstack(a:lnum, l:col), "synIDattr(v:val, 'name')")
endfu

fu! IsSynstackCss(synstack)
  return get(a:synstack, -1) =~# '^css'
endfu

" Does synstack end with an xml syntax attribute
fu! IsSynstackHtml(synstack)
  return get(a:synstack, -1) =~# '^html'
endfu

fu! IsSynstackJs(synstack)
  return get(a:synstack, -1) =~# '^js'
endfu

fu! VHTL_isSynstackInsideLitHtml(synstack)
  for l:syntaxAttribute in reverse(copy((a:synstack)))
    if (l:syntaxAttribute ==# 'litHtmlRegion')
      return v:true
    endif
  endfor
  return v:false
endfu

fu! IsSynstackInsideJsx(synstack)
  for l:syntaxAttribute in reverse(copy((a:synstack)))
    if (l:syntaxAttribute =~# '^jsx')
      return v:true
    endif
  endfor
  return v:false
endfu

fu! VHTL_closesJsExpression(str)
  return (VHTL_getBracketDepthChange(a:str) < 0)
endfu
fu! VHTL_getBracketDepthChange(str)
  let l:depth=0
  for l:char in split(a:str, '\zs')
    if (l:char ==# '{')
      let l:depth += 1
    elseif (l:char ==# '}')
      let l:depth -=1
    endif
  endfor
  return l:depth
endfu

fu! VHTL_startsWithTemplateEnd(linenum)
  return (getline(a:linenum)) =~# '^\s*`'
endfu

fu! VHTL_opensTemplate(line)
  let l:index = 0
  let l:depth = 0
  while v:true
    let [l:term, l:index, l:trash] = matchstrpos(a:line, '\Mhtml`\|\\`\|`', l:index)
    if (l:index == -1)
      return (l:depth > 0)
    endif
    if (l:term ==# 'html`')
      let l:index += len('html`')
      let l:depth += 1
    elseif(l:term ==# '`')
      let l:index += len('`')
      if (l:depth > 0)
        let l:depth -= 1
      endif
    endif
  endwhile
endfu

fu! VHTL_closesTemplate(line)
  let l:index = 0
  let l:depth = 0
  while v:true
    let [l:term, l:index, l:trash] = matchstrpos(a:line, '\Mhtml`\|\\`\|`', l:index)
    if (l:index == -1)
      return v:false
    endif
    if (l:term ==# 'html`')
      let l:index += len('html`')
      let l:depth += 1
    elseif(l:term ==# '`')
      let l:index += len('`')
      let l:depth -= 1
      if (l:depth < 0)
        return v:true
      endif
    endif
  endwhile
endfu

fu! VHTL_closesTag(line)
  return (-1 != match(a:line, '^\s*<\/'))
  " todo: what about <div></div></div> ?
endfu

fu! VHTL_getHtmlTemplateDepthChange(line)
  let l:templateOpeners = VHTL_countMatches(a:line, 'html`')
  let l:escapedTics     = VHTL_countMatches(a:line, '\M\\`')
  let l:templateClosers = VHTL_countMatches(a:line, '`') - l:templateOpeners - l:escapedTics
  let l:depth = l:templateOpeners - l:templateClosers
  return l:depth
endfu

fu! VHTL_countMatches(string, pattern)
  let l:count = 0
  let l:lastMatch = -1
  while v:true
    let l:lastMatch = match(a:string, a:pattern, l:lastMatch+1)
    if (-1 == l:lastMatch)
      return l:count
    else
      let l:count += 1
    endif
  endwhile
endfu

let g:VHTL_debugging = 1
if exists('g:VHTL_debugging')
  set debug=msg " show errors in indentexpr
endif
fu! VHTL_debug(str)
  if exists('g:VHTL_debugging')
    echom a:str
  endif
endfu

" Dispatch to indent method for js/html (use custom rules for transitions
" between syntaxes)
fu! ComputeLitHtmlIndent()

  " get most recent non-empty line
  let l:prev_lnum = prevnonblank(v:lnum - 1)

  let l:currLineSynstack = VHTL_SynSOL(v:lnum)
  let l:prevLineSynstack = VHTL_SynEOL(l:prev_lnum)

  if (!VHTL_isSynstackInsideLitHtml(l:currLineSynstack) && !VHTL_isSynstackInsideLitHtml(l:prevLineSynstack))
    call VHTL_debug('outside of litHtmlRegion')
    return eval(b:litHtmlOriginalIndentExpression)
  endif


  let l:wasCss = (IsSynstackCss(l:prevLineSynstack))

  " We add an extra dedent for closing } brackets, as long as the matching {
  " opener is not on the same line as an opening html`.
  "
  " This algorithm does not always work and must be rewritten (hopefully to
  " something simpler)
  let l:adjustForClosingBracket = 0
  " if (!l:wasCss && VHTL_closesJsExpression(getline(l:prev_lnum)))
  "   :exec 'normal! ' . l:prev_lnum . 'G0[{'
  "   let l:lineWithOpenBracket = getline(line('.'))
  "   if (!VHTL_opensTemplate(l:lineWithOpenBracket))
  "     call VHTL_debug('adjusting for close bracket')
  "     let l:adjustForClosingBracket = - &shiftwidth
  "   endif
  " endif

  let l:wasHtml = (IsSynstackHtml(l:prevLineSynstack))
  let l:isHtml  = (IsSynstackHtml(l:currLineSynstack))
  let l:wasCss  = (IsSynstackCss(l:prevLineSynstack))
  let l:isCss   = (IsSynstackCss(l:currLineSynstack))
  let l:wasJs   = (IsSynstackJs(l:prevLineSynstack))
  let l:isJs    = (IsSynstackJs(l:currLineSynstack))

  " If a line starts with template close, it is dedented. If a line otherwise
  " contains a template close, the NEXT line is dedented. Note that template
  " closers can be balanced out by template openers.
  if (VHTL_startsWithTemplateEnd(v:lnum))
    call VHTL_debug('closed template at start ')
    let l:result = indent(l:prev_lnum) - &shiftwidth
    if (VHTL_closesJsExpression(getline(l:prev_lnum)))
      call VHTL_debug('closed template at start and js expression')
      let l:result -= &shiftwidth
    endif
    return l:result
  endif
  if (VHTL_opensTemplate(getline(l:prev_lnum)))
    call VHTL_debug('opened template')
    return indent(l:prev_lnum) + &shiftwidth
  elseif (VHTL_closesTemplate(getline(l:prev_lnum)) && !VHTL_startsWithTemplateEnd(l:prev_lnum))
    call VHTL_debug('closed template ' . l:adjustForClosingBracket)
    let l:result = indent(l:prev_lnum) - &shiftwidth + l:adjustForClosingBracket
    if (VHTL_closesTag(getline(v:lnum)))
      call VHTL_debug('closed template and tag ' . l:adjustForClosingBracket)
      let l:result -= &shiftwidth
    endif
    return l:result
  elseif (l:isHtml && l:wasJs && VHTL_closesJsExpression(getline(l:prev_lnum)))
    let l:result = indent(l:prev_lnum) - &shiftwidth
    call VHTL_debug('closes expression')
    if (VHTL_closesTag(getline(v:lnum)))
      let l:result -= &shiftwidth
      call VHTL_debug('closes expression and tag')
    endif
    return l:result
  endif

  let l:isJsx  = (IsSynstackInsideJsx(l:currLineSynstack))
  if (l:wasCss || l:isCss || l:wasHtml || l:isHtml) && !l:isJsx
    call VHTL_debug('html indent ' . l:adjustForClosingBracket)
    return HtmlIndent() + l:adjustForClosingBracket
  endif

  if len(b:litHtmlOriginalIndentExpression)
    call VHTL_debug('js indent ' . b:litHtmlOriginalIndentExpression)
    return eval(b:litHtmlOriginalIndentExpression)
  else
    call VHTL_debug('cindent should never happen')
    return cindent(v:lnum)
  endif
endfu
