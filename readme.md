Syntax highlighting and indentation for
[**lit-html**](https://github.com/Polymer/lit-html). Largely inspired by
[**vim-jsx**](https://github.com/mxw/vim-jsx).

## Supported Syntaxes inside ``html`...` ``
- Xml tags
- JavaScript string interpolation (`${...}`)
- Embedded CSS

## Installation

This plugin requires
[**vim-javascript**](https://github.com/pangloss/vim-javascript). If you use
[**vim-plug**](https://github.com/junegunn/vim-plug) for package management,
installation looks like this:

```vim
Plug 'jonsmithers/experimental-lit-html-vim'
Plug 'pangloss/vim-javascript'
```

## Known Issues

- The indentation logic still has some kinks.
  <!-- The boundaries between js and html (``html`...` `` and `${...}`) are
  rather tricky. -->
- This plugin conflicts a bit with vim-jsx. Having both installed
  simultaneously may result in undesired indentation behaviors.
  
## Tip

- It's generally a good idea to have `let g:html_indent_style1 = "inc"` in your
  vimrc for reasonable indentation of `<style>` tags. See `:help
  html-indenting`.
