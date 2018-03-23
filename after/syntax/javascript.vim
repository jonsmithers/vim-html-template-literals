" Add xml highlighting inside html`...` expressions

if exists('b:current_syntax')
  let s:current_syntax=b:current_syntax
  unlet b:current_syntax
endif
syn include @XMLSyntax syntax/xml.vim
if exists('s:current_syntax')
  let b:current_syntax=s:current_syntax
endif

syntax region litHtmlRegion
  \ contains=@XMLSyntax,jsTemplateExpression,litHtmlStyleTag
  \ skip=+\\`+ 
  \ start=+html`+
  \ end=+`+
syn cluster jsExpression add=litHtmlRegion


" Add css highlighting inside <style> tags

if exists('b:current_syntax')
  let s:current_syntax=b:current_syntax
  unlet b:current_syntax
endif
syn include @CSSSyntax syntax/css.vim
if exists('s:current_syntax')
  let b:current_syntax=s:current_syntax
endif

syntax region litHtmlStyleTag contained
  \ contains=@CSSSyntax
  \ start=+ <style>+
  \ end=+</style>+
  \ keepend
  " this space in front of "<style>" is a hack to get priority over xml
  " xmlTagName (see :help syn-priority)
