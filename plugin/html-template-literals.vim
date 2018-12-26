augroup html-template-literals
  au!
  autocmd FileType javascript,javascript.jsx call htmltemplateliterals#amendSyntax({'typescript': 0})
  autocmd FileType javascript,javascript.jsx call htl_indent#amendIndentation({'typescript': 0})
  autocmd FileType typescript                call htmltemplateliterals#amendSyntax({'typescript': 1})
  autocmd FileType typescript                call htl_indent#amendIndentation({'typescript': 1})
augroup END
