function! htmltemplateliterals#amendSyntax(options)
  if exists('b:current_syntax')
    let s:current_syntax=b:current_syntax
    unlet b:current_syntax
  endif
  syn include @HTMLSyntax syntax/html.vim
  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  endif

  if (a:options.typescript == 1)
    syntax region litHtmlRegion
          \ contains=@HTMLSyntax,typescriptInterpolation
          \ start=+html`+
          \ skip=+\\`+
          \ end=+`+
          \ extend
          \ keepend
  else
    syntax region litHtmlRegion
          \ contains=@HTMLSyntax,jsTemplateExpression
          \ start=+html`+
          \ skip=+\\`+
          \ end=+`+
          \ extend
          \ keepend
  endif

  if (a:options.typescript)
    syn cluster typescriptExpression add=litHtmlRegion
  else
    syn cluster jsExpression         add=litHtmlRegion
  endif

  " allow js interpolation (${...}) inside html strings 
  if (a:options.typescript)
    syntax region jsTemplateExpressionLitHtmlWrapper contained start=+${+ end=+}+ contains=typescriptInterpolation keepend containedin=htmlString,htmlComment
  else
    syntax region jsTemplateExpressionLitHtmlWrapper contained start=+${+ end=+}+ contains=jsTemplateExpression    keepend containedin=htmlString,htmlComment
  endif

  " prevent htmlValue from overextending because it will match on js expression
  if (a:options.typescript)
    syntax region jsTemplateExpressionAsHtmlValue start=+=[\t ]*${+ end=++ contains=typescriptInterpolation containedin=htmlTag
  else
    syntax region jsTemplateExpressionAsHtmlValue start=+=[\t ]*${+ end=++ contains=jsTemplateExpression    containedin=htmlTag
  endif

endfunction
