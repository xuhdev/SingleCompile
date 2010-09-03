" File: plugin/SingleCompile.vim
" GetLatestVimScripts: 3115 1 :AutoInstall: SingleCompile.zip
" version 1.2.1
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

" templates {{{1

" c
call SingleCompile#SetTemplate('c','command','cc',1)
call SingleCompile#SetTemplate('c','flags','-o %<',1)
if has('win32') || has('win64')
    call SingleCompile#SetTemplate('c','run','%<',1)
else
    call SingleCompile#SetTemplate('c','run','./'.'%<',1)
endif

" cpp
call SingleCompile#SetTemplate('cpp','command','g++',1)
call SingleCompile#SetTemplate('cpp','flags',g:SingleCompile_templates['c']['flags'],1)
call SingleCompile#SetTemplate('cpp','run',g:SingleCompile_templates['c']['run'],1)

" java
call SingleCompile#SetTemplate('java','command','javac',1)
call SingleCompile#SetTemplate('java','flags','',1)
call SingleCompile#SetTemplate('java','run','java %<',1)

" shell
call SingleCompile#SetTemplate('sh','command','sh',1)
call SingleCompile#SetTemplate('sh','flags','',1)
call SingleCompile#SetTemplate('sh','run','',1)

" dosbatch
call SingleCompile#SetTemplate('dosbatch','command','',1)
call SingleCompile#SetTemplate('dosbatch','flags','',1)
call SingleCompile#SetTemplate('dosbatch','run','',1)

" html
if has('win32') || has('win64')
    call SingleCompile#SetTemplate('html','command',"start \"C:\\Program Files\\Internet Explorer\\iexplore.exe\"",1)
elseif has('unix')
    call SingleCompile#SetTemplate('html','command','firefox',1)
endif
call SingleCompile#SetTemplate('html','flags','',1)
call SingleCompile#SetTemplate('html','run','',1)

" xhtml
call SingleCompile#SetTemplate('xhtml','command',g:SingleCompile_templates['html']['command'],1)
call SingleCompile#SetTemplate('xhtml','flags',g:SingleCompile_templates['html']['flags'],1)
call SingleCompile#SetTemplate('xhtml','run',g:SingleCompile_templates['html']['run'],1)

" vbs
call SingleCompile#SetTemplate('vb','command','cscript',1)
call SingleCompile#SetTemplate('vb','flags','',1)
call SingleCompile#SetTemplate('vb','run','',1)

" latex
call SingleCompile#SetTemplate('tex','command','latex',1)
call SingleCompile#SetTemplate('tex','flags','',1)
if has('unix')
    call SingleCompile#SetTemplate('tex','run','xdvi %<.dvi',1)
elseif has('win32') || has('win64')
    call SingleCompile#SetTemplate('tex','run','dviout %<.dvi',1)
endif

" plain tex
call SingleCompile#SetTemplate('plaintex','command',g:SingleCompile_templates['tex']['command'],1)
call SingleCompile#SetTemplate('plaintex','flags',g:SingleCompile_templates['tex']['flags'],1)
call SingleCompile#SetTemplate('plaintex','run',g:SingleCompile_templates['tex']['run'],1)

" python
call SingleCompile#SetTemplate('python','command','python',1)
call SingleCompile#SetTemplate('python','flags','',1)
call SingleCompile#SetTemplate('python','run','',1)

" perl
call SingleCompile#SetTemplate('perl','command','perl',1)
call SingleCompile#SetTemplate('perl','flags','',1)
call SingleCompile#SetTemplate('perl','run','',1)

" ruby
call SingleCompile#SetTemplate('ruby','command','ruby',1)
call SingleCompile#SetTemplate('ruby','flags','',1)
call SingleCompile#SetTemplate('ruby','run','',1)

" lua
call SingleCompile#SetTemplate('lua','command','lua',1)
call SingleCompile#SetTemplate('lua','flags','',1)
call SingleCompile#SetTemplate('lua','run','',1)

" Makefile
call SingleCompile#SetTemplate('make','command','make',1)
call SingleCompile#SetTemplate('make','flags','-f',1)
call SingleCompile#SetTemplate('make','run','',1)

" cmake
call SingleCompile#SetTemplate('cmake','command','cmake',1)
call SingleCompile#SetTemplate('cmake','flags','',1)
call SingleCompile#SetTemplate('cmake','run','',1)


" commands {{{1
command -nargs=* SingleCompile       if <q-args> == '' | call SingleCompile#Compile() | else | call SingleCompile#Compile(<q-args>) | endif
command -nargs=* SingleCompileRun    if <q-args> == '' | call SingleCompile#CompileRun() | else | call SingleCompile#CompileRun(<q-args>) | endif

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
