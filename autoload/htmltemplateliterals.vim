function! htmltemplateliterals#amendSyntax()
  if exists('b:current_syntax')
    let s:current_syntax=b:current_syntax
    unlet b:current_syntax
  endif
  syn include @HTMLSyntax syntax/html.vim
  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  endif

  syntax region litHtmlRegion
        \ contains=@HTMLSyntax,jsTemplateExpression
        \ start=+html`+
        \ skip=+\\`+
        \ end=+`+
        \ extend
        \ keepend
  " \ skip=+\(\\\|html\)`+
  syn cluster jsExpression add=litHtmlRegion

  " allow js interpolation (${...}) inside html strings 
  syntax region jsTemplateExpressionLitHtmlWrapper contained start=+${+ end=+}+ contains=jsTemplateExpression keepend containedin=htmlValue,htmlString,htmlComment

endfunction
