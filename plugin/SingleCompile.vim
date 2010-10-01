" File: plugin/SingleCompile.vim
" GetLatestVimScripts: 3115 1 :AutoInstall: SingleCompile.zip
" version 2.0
" check doc/SingleCompile.txt for more version information

if v:version < 700
    finish
endif

" check whether this script is already loaded
if exists("g:loaded_SingleCompile")
    finish
endif
let g:loaded_SingleCompile = 1

let s:saved_cpo = &cpo
set cpo&vim


" commands {{{1
command -nargs=* SCCompile       if <q-args> == '' | call SingleCompile#Compile() | else | call SingleCompile#Compile(<q-args>) | endif
command -nargs=* SCCompileRun    if <q-args> == '' | call SingleCompile#CompileRun() | else | call SingleCompile#CompileRun(<q-args>) | endif
command -nargs=* SingleCompile       if <q-args> == '' | call SingleCompile#Compile() | else | call SingleCompile#Compile(<q-args>) | endif
command -nargs=* SingleCompileRun    if <q-args> == '' | call SingleCompile#CompileRun() | else | call SingleCompile#CompileRun(<q-args>) | endif
command SCChooseCompiler call SingleCompile#ChooseCompiler(&filetype)

" menu {{{1

if !exists('g:SingleCompile_menumode')
    let g:SingleCompile_menumode = 1
endif

if has('gui_running') && has('menu')
    if g:SingleCompile_menumode == 1
        nnoremenu Plugin.SingleCompile.&Compile<tab>:SingleCompile :SingleCompile<cr>
        nnoremenu Plugin.SingleCompile.Compile\ and\ &run<tab>:SingleCompileRun :SingleCompileRun<cr>
        inoremenu Plugin.SingleCompile.&Compile<tab>:SingleCompile <C-O>:SingleCompile<cr>
        inoremenu Plugin.SingleCompile.Compile\ and\ &run<tab>:SingleCompileRun <C-O>:SingleCompileRun<cr>
        vnoremenu Plugin.SingleCompile.&Compile<tab>:SingleCompile <Esc>:SingleCompile<cr>
        vnoremenu Plugin.SingleCompile.Compile\ and\ &run<tab>:SingleCompileRun <Esc>:SingleCompileRun<cr>
    elseif g:SingleCompile_menumode == 2
        nnoremenu SingleCompile.&Compile<tab>:SingleCompile :SingleCompile<cr>
        nnoremenu SingleCompile.Compile\ and\ &run<tab>:SingleCompileRun :SingleCompileRun<cr>
        inoremenu SingleCompile.&Compile<tab>:SingleCompile <C-O>:SingleCompile<cr>
        inoremenu SingleCompile.Compile\ and\ &run<tab>:SingleCompileRun <C-O>:SingleCompileRun<cr>
        vnoremenu SingleCompile.&Compile<tab>:SingleCompile <Esc>:SingleCompile<cr>
        vnoremenu SingleCompile.Compile\ and\ &run<tab>:SingleCompileRun <Esc>:SingleCompileRun<cr>
    endif
endif

" }}}


" vim-addon-actions support (activate this addon after vim-addon-actions) {{{
" eg call scriptmanager#Activate(["vim-addon-actions","SingleCompile"])
  if exists('g:vim_actions')
    for cmd in ['SingleCompile','SingleCompileRun']
      call actions#AddAction('run '.cmd, {'action': funcref#Function('return '.string([cmd]))})
    endfor
  endif
"}}}

let &cpo = s:saved_cpo

" vim:fdm=marker
