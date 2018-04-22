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
exe 'runtime! indent/xml.vim'
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
fu! SynSOL(lnum)
  return map(synstack(a:lnum, 1), "synIDattr(v:val, 'name')")
endfu

" Get syntax stack at EndOfLine
fu! SynEOL(lnum)
  let l:lnum = prevnonblank(a:lnum)
  let l:col = strlen(getline(l:lnum))
  return map(synstack(l:lnum, l:col), "synIDattr(v:val, 'name')")
endfu

fu! IsSyntaxCss(synstack)
  return get(a:synstack, -1) =~# '^css' || get(a:synstack, -1) =~# '^litHtmlStyleTag$'
endfu

" Does synstack end with an xml syntax attribute
fu! IsSynstackXml(synstack)
  return get(a:synstack, -1) =~# '^xml'
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

fu! VHTL_debug(str)
  if exists('g:VHTL_debugging')
    echom a:str
  endif
endfu

" Dispatch to indent method for js/html/css (use custom rules for transitions
" between syntaxes)
fu! ComputeLitHtmlIndent()
  let l:currLineSynstack = SynEOL(v:lnum)
  let l:prevLineSynstack = SynEOL(v:lnum - 1)
  " TODO need to handle empty lines. Currently I assume there are no blank
  " lines.

  if (!VHTL_isSynstackInsideLitHtml(l:currLineSynstack) && !VHTL_isSynstackInsideLitHtml(l:prevLineSynstack))
    call VHTL_debug('outside of litHtmlRegion')
    return eval(b:litHtmlOriginalIndentExpression)
  endif


  let l:wasCss = (IsSyntaxCss(l:prevLineSynstack))

  " We add an extra dedent for closing } brackets, as long as the matching {
  " opener is not on the same line as an opening html`.
  "
  " This algorithm does not always work and must be rewritten (hopefully to
  " something simpler)
  let l:adjustForClosingBracket = 0
  if (!l:wasCss && VHTL_getBracketDepthChange(getline(v:lnum - 1)) < 0)
    :normal! 0[{
    let l:openingBracketLine = getline(line('.'))
    if (!VHTL_opensTemplate(l:openingBracketLine))
      call VHTL_debug('adjusting for close bracket')
      let l:adjustForClosingBracket = - &shiftwidth
    endif
  endif

  " If a line starts with template close, it is dedented. If a line otherwise
  " contains a template close, the NEXT line is dedented. Note that template
  " closers can be balanced out by template openers.
  if (VHTL_startsWithTemplateEnd(v:lnum))
    call VHTL_debug('closed template at start ' . l:adjustForClosingBracket)
    return indent(v:lnum-1) - &shiftwidth + l:adjustForClosingBracket
  endif
  if (VHTL_opensTemplate(getline(v:lnum-1)))
    call VHTL_debug('opened template')
    return indent(v:lnum-1) + &shiftwidth
  elseif (VHTL_closesTemplate(getline(v:lnum-1)) && !VHTL_startsWithTemplateEnd(v:lnum-1))
    call VHTL_debug('closed template somewhere ' . l:adjustForClosingBracket)
    return indent(v:lnum-1) - &shiftwidth + l:adjustForClosingBracket
  endif

  let l:wasXml = (IsSynstackXml(l:prevLineSynstack))
  let l:isXml  = (IsSynstackXml(l:currLineSynstack))
  let l:isJsx  = (IsSynstackInsideJsx(l:currLineSynstack))
  if (l:wasXml || l:isXml) && !l:isJsx
    call VHTL_debug('xml indent ' . l:adjustForClosingBracket)
    return XmlIndentGet(v:lnum, 0) + l:adjustForClosingBracket
  endif

  let l:isCss = (IsSyntaxCss(l:currLineSynstack))
  if l:isCss
    call VHTL_debug('css indent')
    return GetCSSIndent()
  endif

  if len(b:litHtmlOriginalIndentExpression)
    call VHTL_debug('js indent ' . b:litHtmlOriginalIndentExpression)
    return eval(b:litHtmlOriginalIndentExpression)
  else
    call VHTL_debug('cindent should never happen')
    return cindent(v:lnum)
  endif
endfu
