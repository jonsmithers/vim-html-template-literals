augroup html-template-literals
  au!
  autocmd FileType javascript,javascriptreact,javascript.jsx call htl_syntax#amend({'typescript': 0})
  autocmd FileType javascript,javascriptreact,javascript.jsx call htl_indent#amend({'typescript': 0})
  autocmd FileType typescript,typescriptreact                call htl_syntax#amend({'typescript': 1})
  autocmd FileType typescript,typescriptreact                call htl_indent#amend({'typescript': 1})
augroup END
