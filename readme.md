Syntax highlighting and indentation for
[**lit-html**](https://github.com/Polymer/lit-html). Largely inspired by
[**vim-jsx**](https://github.com/mxw/vim-jsx).

## Supported Syntaxes inside ``html`...` ``
- HTML (including CSS embedded in `<style>` tags)
- JavaScript string interpolation (`${...}`)
- nested templates (``` html`${html`${}`}` ```)

## Installation

This plugin requires
[**vim-javascript**](https://github.com/pangloss/vim-javascript). If you use
[**vim-plug**](https://github.com/junegunn/vim-plug) for package management,
installation looks like this:

```vim
Plug 'jonsmithers/experimental-lit-html-vim'
Plug 'pangloss/vim-javascript'
```

Note: it's generally a good idea to have `let g:html_indent_style1 = "inc"` in
your vimrc for reasonable indentation of `<style>` tags. See `:help
html-indenting`.

## Known Issues

- Indentation in TypeScript is not implemented yet.
- Indentation in general still has some kinks. If you see an issue, please
  report it.
- This plugin conflicts a bit with vim-jsx. Having both installed
  simultaneously may result in undesired indentation behaviors.
