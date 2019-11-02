# HTML Template Literals
Syntax highlighting and indentation for html inside of tagged template
literals, as seen in [lit-html](https://github.com/Polymer/lit-html) and
[Polymer 3](https://polymer-library.polymer-project.org/3.0/docs/about_30).

## Supported Syntaxes inside ``html`...` ``
- HTML (including CSS embedded in `<style>` tags)
- JavaScript string interpolation (`${...}`)
- nested templates (``` html`${html`${}`}` ```)

## Installation

This plugin requires
[vim-javascript](https://github.com/pangloss/vim-javascript) (or
[typescript-vim](https://github.com/leafgarland/typescript-vim) if you're using
typescript). If you use [vim-plug](https://github.com/junegunn/vim-plug) for
package management, installation looks like this:

```vim
Plug 'jonsmithers/vim-html-template-literals'
Plug 'pangloss/vim-javascript'
```

_NOTE_: it's generally a good idea to have `let g:html_indent_style1 = "inc"` in
your vimrc for reasonable indentation of `<style>` tags. See `:help
html-indenting`.

## Configuration

| Flag                  | Description                                                                                                           |
| --------------------  | --------------------------------------------------------------------------------------------------------------------- |
| `g:htl_css_templates` | Enable css syntax inside css-tagged template literals (`` css`...` ``) (auto-indent is currently not supported here). |
| `g:htl_all_templates` | (Experimental) Enable html syntax inside _all_ template literals (`` `...` ``).                                       |

## Known Issues

- Indentation in general still has some kinks. If you see an issue, please
  report it.
- This plugin conflicts a bit with vim-jsx. Having both installed
  simultaneously may result in undesired indentation behaviors.
  
## Tips

- You can configure the [vim-closetag] plugin to work inside html template
  literals:

  ```vim
  let g:closetag_filetypes = 'html,xhtml,phtml,javascript,typescript'
  let g:closetag_regions = {
        \ 'typescript.tsx': 'jsxRegion,tsxRegion,litHtmlRegion',
        \ 'javascript.jsx': 'jsxRegion,litHtmlRegion',
        \ 'javascript':     'litHtmlRegion',
        \ 'typescript':     'litHtmlRegion',
        \ }
  ```

[vim-closetag]: https://github.com/alvan/vim-closetag
