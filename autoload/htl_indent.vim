" Description: Vim html-template-string indent amendments
" Maintainer: Jon Smithers <mail@jonsmithers.link>

if (exists('g:htl_debug') && g:htl_debug == 1)
  exec 'command! HTLReload :source ' . expand('<sfile>') . ' | :edit'
endif

function! htl_indent#amend(options)
  let b:htl_js                 = a:options.typescript ? '^\(typescript\|foldBraces$\)'     : '^js'
  let b:htl_expression_bracket = a:options.typescript ? '\(typescriptInterpolationDelimiter\|typescriptTemplateSB\)' : 'jsTemplateBraces'

  " Save the current JavaScript indentexpr.
  let b:litHtmlOriginalIndentExpression = &indentexpr

  " import html indent
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

endfunction

" Get syntax stack at StartOfLine
fu! s:VHTL_SynSOL(lnum)
  let l:col = match(getline(a:lnum), '\S')
  if (l:col == -1)
    return []
  endif
  return map(synstack(a:lnum, l:col+1), "synIDattr(v:val, 'name')")
endfu

" Get syntax stack at EndOfLine
fu! s:VHTL_SynEOL(lnum)
  if (a:lnum < 1)
    return []
  endif
  let l:col = strlen(getline(a:lnum))
  return map(synstack(a:lnum, l:col), "synIDattr(v:val, 'name')")
endfu

function! s:SynAt(l,c) " from $VIMRUNTIME/indent/javascript.vim
  let l:byte = line2byte(a:l) + a:c - 1
  let l:pos = index(s:synid_cache[0], l:byte)
  if l:pos == -1
    let s:synid_cache[:] += [[l:byte], [synIDattr(synID(a:l, a:c, 0), 'name')]]
  endif
  return s:synid_cache[1][l:pos]
endfunction

" Make debug log. You can view these logs using ':messages'
fu! s:debug(str)
  if (exists('g:htl_debug') && g:htl_debug == 1)
    echom 'htl ' . v:lnum . ': ' . a:str
  endif
endfu

let s:StateClass={}
fu! s:StateClass.new(lnum)
  let l:instance = copy(l:self)
  let l:instance.currLine = a:lnum
  let l:instance.prevLine = prevnonblank(a:lnum - 1)
  let l:instance.currSynstack = s:VHTL_SynSOL(l:instance.currLine)
  let l:instance.prevSynstack = s:VHTL_SynEOL(l:instance.prevLine)
  return l:instance
endfu

fu! s:StateClass.startsWithTemplateClose() dict
  return (getline(l:self.currSynstack)) =~# '^\s*`'
endfu

fu! s:StateClass.openedJsExpression() dict
  return (VHTL_getBracketDepthChange(getline(l:self.prevLine)) > 0)
endfu
fu! s:StateClass.openedLitHtmlTemplate() dict
  let l:index = 0
  let l:depth = 0
  while v:true
    let [l:term, l:index, l:trash] = matchstrpos(getline(l:self.prevLine), '\Mhtml`\|\\`\|`', l:index)
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

fu! s:StateClass.isInsideLitHtml() dict
  for l:syntaxAttribute in reverse(copy(l:self.currSynstack))
    if (l:syntaxAttribute ==# 'litHtmlRegion')
      return v:true
    endif
  endfor
  return v:false
endfu
fu! s:StateClass.wasInsideLitHtml() dict
  for l:syntaxAttribute in reverse(copy(l:self.prevSynstack))
    if (l:syntaxAttribute ==# 'litHtmlRegion')
      return v:true
    endif
  endfor
  return v:false
endfu

fu! s:StateClass.wasHtml() dict
  return get(l:self.prevSynstack, -1) =~# '^html'
endfu
fu! s:StateClass.isHtml() dict
  return get(l:self.currSynstack, -1) =~# '^html'
endfu
fu! s:StateClass.isLitHtmlRegionCloser() dict
  return get(l:self.currSynstack, -1) ==# 'litHtmlRegion' && getline(l:self.currLine) =~# '^\s*`'
endfu
fu! s:StateClass.opensTemplate() dict
  return get(l:self.currSynstack, -1) ==# 'litHtmlRegion' && getline(l:self.currLine) =~# '^\s*html`'
endfu
fu! s:StateClass.closedTemplate() dict
  return get(l:self.prevSynstack, -1) ==# 'litHtmlRegion' && getline(l:self.prevLine) !~# 'html`$'
endfu
fu! s:StateClass.wasJs() dict
  return get(l:self.prevSynstack, -1) =~# b:htl_js
endfu
fu! s:StateClass.isJs() dict
  return get(l:self.currSynstack, -1) =~# b:htl_js
endfu
fu! s:StateClass.wasExpressionBracket() dict
  return get(l:self.prevSynstack, -1) =~# b:htl_expression_bracket
endfu
fu! s:StateClass.isExpressionBracket() dict
  return get(l:self.currSynstack, -2) =~# b:htl_expression_bracket
endfu
fu! s:StateClass.closedExpression() dict
  return l:self.wasExpressionBracket() && getline(l:self.prevLine)[-1:-1] ==# '}'
endfu
fu! s:StateClass.closesExpression() dict
  return l:self.isExpressionBracket() &&  getline(l:self.currLine)[-1:-1] ==# '}'
endfu
fu! s:StateClass.openedExpression() dict
  return l:self.wasExpressionBracket() && getline(l:self.prevLine)[-1:-1] ==# '{'
endfu
fu! s:StateClass.opensExpression() dict
  return l:self.isExpressionBracket() &&  getline(l:self.currLine)[-1:-1] ==# '{'
endfu
fu! s:StateClass.wasCss() dict
  return get(l:self.prevSynstack, -1) =~# '^css'
endfu
fu! s:StateClass.isCss() dict
  return get(l:self.currSynstack, -1) =~# '^css'
endfu

fu! s:StateClass.toStr() dict
  return '{line ' . l:self.currLine . '}'
endfu

fu! s:SkipFuncJsTemplateBraces()
  " let l:char = getline(line('.'))[col('.')-1]
  let l:syntax = s:SynAt(line('.'), col('.'))
  if (l:syntax !~# b:htl_expression_bracket)
    return 1
  endif
endfu

fu! s:SkipFuncHtmlTag()
  " call s:debug('SkipFuncHtmlTag col ' . col('.') . ': ' . synIDattr(synID(line('.'), col('.'), 0), 'name'))
  return (synIDattr(synID(line('.'), col('.'), 0), 'name') !~# '^html')
endfu

fu! s:SkipFuncLitHtmlRegion()
  " let l:char = getline(line('.'))[col('.')-1]
  let l:syntax = s:SynAt(line('.'), col('.'))
  if (l:syntax !=# 'litHtmlRegion')
    return 1
  endif
endfu

fu! s:getCloseWordsLeftToRight(lineNum)
  let l:line = getline(a:lineNum)

  " The following regex converts a line to purely a list of closing words.
  " Pretty cool but not useful
  " echo split(getline(62), '.\{-}\ze\(}\|`\|<\/\w\+>\)')

  let l:anyCloserWord =  '}\|`\|<\/\w\+>'


  let l:index = 0
  let l:closeWords = []
  while v:true
    let [l:term, l:index, l:trash] = matchstrpos(l:line, l:anyCloserWord, l:index)
    if (l:index == -1)
      break
    else
      let l:col = l:index + 1
      call add(l:closeWords, [l:term, l:col])
    endif
    let l:index += 1
  endwhile
  return l:closeWords
endfu

fu! s:StateClass.getIndentDelta() dict
  let l:closeWords = s:getCloseWordsLeftToRight(l:self.currLine)
  if len(l:closeWords) == 0
    call s:debug('getIndentDelta: no closeWords')
    return 0
  endif
  let [l:closeWord, l:col] = l:closeWords[0]
  let l:syntax = s:SynAt(l:self.currLine, l:col)
  if (l:syntax ==# 'htmlEndTag')

    let l:openWord = substitute(substitute(l:closeWord, '/', '', ''), '>', '', '')
    call cursor(l:self.currLine, l:col) " set start point for searchpair()
    call searchpair(l:openWord, '', l:closeWord, 'bW', 's:SkipFuncHtmlTag()')
    " call searchpair(l:openWord, '', l:closeWord, 'bW')
    call s:debug('closeword ' . l:closeWord)
    if (line('.') ==# l:self.currLine)
      call s:debug('getIndentDelta: self-closed html tag')
      call s:debug(line('.'))
      return 0
    else
      call s:debug('getIndentDelta: closing html tag!!!')
      call s:debug(line('.'))
      return - &shiftwidth
    endif
  endif
  if (l:syntax ==# 'litHtmlRegion' && 'html`' !=# strpart(getline(l:self.currLine), l:col-5, len('html`')))
    call s:debug('getIndentDelta: end of litHtmlRegion')
    return - &shiftwidth
  endif
  call s:debug('getIndentDelta: no delta found')
  return 0
endfu

" html tag, html template, or js expression on previous line
fu! s:StateClass.getIndentOfLastClose() dict

  let l:closeWords = s:getCloseWordsLeftToRight(l:self.prevLine)

  if (len(l:closeWords) == 0)
    call s:debug('getIndentOfLastClose: no close words found')
    return -1
  endif

  for l:item in reverse(l:closeWords)
    let [l:closeWord, l:col] = l:item
    let l:syntax = s:SynAt(l:self.prevLine, l:col)
    call cursor(l:self.prevLine, l:col) " sets start point for searchpair()
    if ('}' ==# l:closeWord && l:syntax =~# b:htl_expression_bracket)
      call searchpair('{', '', '}', 'bW', 's:SkipFuncJsTemplateBraces()')
      call s:debug('getIndentOfLastClose: js brace base indent')
    elseif ('`' ==# l:closeWord && l:syntax ==# 'litHtmlRegion')
      call searchpair('html`', '', '\(html\)\@<!`', 'bW', 's:SkipFuncLitHtmlRegion()')
      call s:debug('getIndentOfLastClose: lit html region base indent ')
    elseif (l:syntax ==# 'htmlEndTag')
      let l:openWord = substitute(substitute(l:closeWord, '/', '', ''), '>', '', '')
      call searchpair(l:openWord, '', l:closeWord, 'bW', 's:SkipFuncHtmlTag()')
      call s:debug('getIndentOfLastClose: html tag region base indent ')
    else
      call s:debug('getIndentOfLastClose: UNRECOGNIZED CLOSER SYNTAX: "' . l:syntax . '"')
    endif
    return indent(line('.')) " cursor was moved by searchpair()
  endfor
endfu

" com! MyTest exec "call s:StateClass.new().getIndentOfLastClose()"

" Dispatch to indent method for js/html (use custom rules for transitions
" between syntaxes)
fu! ComputeLitHtmlIndent()
  let s:synid_cache = [[],[]]

  let l:state = s:StateClass.new(v:lnum)

  " get most recent non-empty line
  let l:prev_lnum = prevnonblank(v:lnum - 1)

  if (!l:state.isInsideLitHtml() && !l:state.wasInsideLitHtml())
    call s:debug('outside of litHtmlRegion: ' . b:litHtmlOriginalIndentExpression)

    if (exists('b:hi_indent') && has_key(b:hi_indent, 'blocklnr'))
      call remove(b:hi_indent, 'blocklnr')
       " This avoids a really weird behavior when indenting first line inside
       " style tag and then indenting any normal javascript outside of
       " lit-html region. 'blocklnr' is assigned to line number of <style>,
       " which is then assigned to 'nest' inside vim-javascript's indent code.
    endif
    return eval(b:litHtmlOriginalIndentExpression)
  endif

  if (l:state.openedLitHtmlTemplate())
    call s:debug('opened html template literal')
    if (getline(l:state.currLine) =~# '^\s*`')
      " The first character closes template on previous line. This is a tiny
      " but very common edge case when typing out a new template from scratch.
      call s:debug('closes html template literal in first character')
      return indent(l:prev_lnum)
    else
      call s:debug('first line of template is always indented')
      return indent(l:prev_lnum) + &shiftwidth
    endif
  endif

  if (l:state.openedExpression())
    call s:debug('opened js expression')
    return indent(l:prev_lnum) + &shiftwidth
  endif

  if (l:state.closedExpression() || l:state.isLitHtmlRegionCloser())
    " let l:indent_basis = previous matching js or template start
    " let l:indent_delta = -1 for starting with closing tag, template, or expression
    let l:indent_basis = l:state.getIndentOfLastClose()
    if (l:indent_basis == -1)
      call s:debug('using html indent as base indent')
      let l:indent_basis = HtmlIndent()
    endif
    let l:indent_delta = l:state.getIndentDelta()
    call s:debug('indent delta ' . l:indent_delta)
    call s:debug('indent basis ' . l:indent_basis)
    return l:indent_basis + l:indent_delta
  endif

  if (((l:state.wasJs() && !l:state.closedExpression()) || l:state.closedTemplate()) && ((l:state.isJs() || l:state.opensTemplate())))
    call s:debug('using javascript indent')
    return eval(b:litHtmlOriginalIndentExpression)
  endif

  call s:debug('default to html indent')
  return HtmlIndent()
endfu
