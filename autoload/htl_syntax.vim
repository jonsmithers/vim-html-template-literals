function! htl_syntax#amend(options)

  let l:css_templates  =(exists('g:htl_css_templates')  && g:htl_css_templates)
  let l:all_templates =(exists('g:htl_all_templates') && g:htl_all_templates)

  if exists('b:current_syntax')
    let s:current_syntax=b:current_syntax
    unlet b:current_syntax
  endif
  syn include @HTMLSyntax syntax/html.vim
  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  endif

  if (l:css_templates)
    if exists('b:current_syntax')
      let s:current_syntax=b:current_syntax
      unlet b:current_syntax
    endif
    syn include @CSSSyntax syntax/css.vim
    if exists('s:current_syntax')
      let b:current_syntax=s:current_syntax
    endif
  endif

  if (&filetype ==# 'javascript.jsx')
    " sourcing html syntax will re-source javascript syntax because html has
    " <script> tags. However, re-sourcing javascript will erase jsx
    " modifications, so we need to additionally re-source jsx syntax.
    runtime syntax/jsx.vim
  endif

  exec 'syntax region litHtmlRegion
        \ contains=@HTMLSyntax,' . (a:options.typescript ? 'typescriptInterpolation' : 'jsTemplateExpression') . '
        \ start=' . (l:all_templates ? '+\(html\)\?`+' : '+html`+') . '
        \ skip=+\\`+
        \ end=+`+
        \ extend
        \ keepend
        \ '
  if (l:all_templates)
    hi def link litHtmlRegion String
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

  if (l:css_templates)
    exec 'syntax region cssLiteral
          \ contains=@CSSSyntax,' . (a:options.typescript ? 'typescriptInterpolation' : 'jsTemplateExpression') . '
          \ start=+css`+
          \ skip=+\\`+
          \ end=+`+
          \ extend
          \ keepend
          \ '

    if (a:options.typescript)
      syn cluster typescriptExpression add=cssLiteral
   else
      syn cluster jsExpression         add=cssLiteral
    endif

    " allow js interpolation (${...}) inside css attributes
    if (a:options.typescript)
      syntax region cssTemplateExpressionWrapper contained start=+${+ end=+}+ contains=typescriptInterpolation keepend containedin=cssAttrRegion
    else
      syntax region cssTemplateExpressionWrapper contained start=+${+ end=+}+ contains=jsTemplateExpression    keepend containedin=cssAttrRegion
    endif
  endif
endfunction
