if exists('b:current_syntax')
  let s:current_syntax=b:current_syntax
  unlet b:current_syntax
endif
syn include @XMLSyntax syntax/xml.vim
if exists('s:current_syntax')
  let b:current_syntax=s:current_syntax
endif

syntax region litHtmlRegion
  \ contains=@XMLSyntax,jsTemplateExpression
  \ skip=+\\`+ 
  \ start=+html`+
  \ end=+`+
syn cluster jsExpression add=litHtmlRegion
