"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim indent file
"
" Copied from https://github.com/mxw/vim-jsx/blob/master/after/indent/jsx.vim
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Save the current JavaScript indentexpr.
let b:lithtml_original_indent_expr = &indentexpr

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

setlocal indentexpr=GetLitHtmlIndent()

" JS indentkeys
setlocal indentkeys=0{,0},0),0],0\,,!^F,o,O,e
" XML indentkeys
setlocal indentkeys+=*<Return>,<>>,<<>,/

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
  return get(a:synstack, -1) =~# '^css'
endfu

" Does synstack end with an xml syntax attribute
fu! IsSynstackXml(synstack)
  return get(a:synstack, -1) =~# '^xml'
endfu

" Dispatch to indent method for js/html/css
fu! GetLitHtmlIndent()
  let l:cursyn  = SynSOL(v:lnum)
  let l:prevsyn = SynEOL(v:lnum - 1)

  if (IsSynstackXml(l:prevsyn))
    let l:ind = XmlIndentGet(v:lnum, 0)
  elseif (IsSyntaxCss(l:prevsyn))
    let l:ind = GetCSSIndent()
  else
    if len(b:lithtml_original_indent_expr)
      " Invoke the base JS package's custom indenter.  (For vim-javascript,
      " e.g., this will be GetJavascriptIndent().)
      let l:ind = eval(b:lithtml_original_indent_expr)
    else
      let l:ind = cindent(v:lnum)
    endif
  endif

  return l:ind
endfu
