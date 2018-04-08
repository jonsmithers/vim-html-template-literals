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

fu! IsSynstackInsideJsx(synstack)
  for l:syntaxAttribute in reverse(copy((a:synstack)))
    if (l:syntaxAttribute =~# '^jsx')
      return v:true
    endif
  endfor
  return v:false
endfu

fu! VHTL_GetBracketDepth(str)
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

" Dispatch to indent method for js/html/css (use custom rules for transitions
" between syntaxes)
fu! ComputeLitHtmlIndent()
  let l:currLineSynstack = SynEOL(v:lnum)
  let l:prevLineSynstack = SynEOL(v:lnum - 1)

  let l:wasTemplateStart = (getline(v:lnum-1) =~# '\<html`\s*$')
  if l:wasTemplateStart
    let l:indent = indent(v:lnum-1)
    let l:isTemplateEnd = (getline(v:lnum) =~# '^\s*`')
    if !l:isTemplateEnd
      " indent first line inside lit-html template
      let l:indent += &shiftwidth
    endif
    return l:indent
  endif

  let l:wasXml = (IsSynstackXml(l:prevLineSynstack))
  let l:isXml  = (IsSynstackXml(l:currLineSynstack))
  let l:isJsx  = (IsSynstackInsideJsx(l:currLineSynstack))
  if (l:wasXml || l:isXml) && !l:isJsx
    let l:isTemplateEnd      = (getline(v:lnum) =~# '^\s*`')
    let l:wasJsExpressionEnd = !IsSyntaxCss(l:prevLineSynstack) && (VHTL_GetBracketDepth(getline(v:lnum-1)) == -1)
    if !l:isTemplateEnd
      let l:indent = XmlIndentGet(v:lnum, 0)
      if l:wasJsExpressionEnd
        let l:indent -= &shiftwidth
      endif
      return l:indent
    else
      return indent(v:lnum-1) - &shiftwidth
    endif
  endif

  let l:isCss = (IsSyntaxCss(l:currLineSynstack))
  if l:isCss
    return GetCSSIndent()
  endif


  if len(b:litHtmlOriginalIndentExpression)
    return eval(b:litHtmlOriginalIndentExpression)
  else
    return cindent(v:lnum)
  endif
endfu
