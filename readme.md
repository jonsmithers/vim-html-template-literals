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

Note that the auto-indent functionality his quite a few flaws and probably
needs to be rewritten. Also, this plugin conflicts a bit with vim-jsx. If you
have it installed, you may experience more undesirable indentation behavior.
