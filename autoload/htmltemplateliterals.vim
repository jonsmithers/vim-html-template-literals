function! htmltemplateliterals#amendSyntax()
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
        \ start=+html`+
        \ skip=+\\`+
        \ end=+`+
        \ extend
        \ keepend
  " \ skip=+\(\\\|html\)`+
  syn cluster jsExpression add=litHtmlRegion

  " allow js interpolation (${...}) inside xml strings 
  syntax region jsTemplateExpressionLitHtmlWrapper contained start=+${+ end=+}+ contains=jsTemplateExpression keepend containedin=xmlString,xmlTag,xmlCommentPart

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
        \ contains=@CSSSyntax,xmlTag,xmlEndTag
        \ start=+\s<style+
        \ end=+</style>+
        \ keepend
  " The space in front of "<style>" is a hack to get priority over xmlTagName
  " (see :help syn-priority)

endfunction
