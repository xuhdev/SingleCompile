" File: plugin/SingleCompile.vim
" GetLatestVimScripts: 3115 1 SingleCompile.zip
" version 2.3.3
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
command -nargs=* SCCompile       
            \if <q-args> == '' | call SingleCompile#Compile() | 
            \else | call SingleCompile#Compile(<q-args>) | endif
command -nargs=* SCCompileRun    
            \if <q-args> == '' | call SingleCompile#CompileRun() | 
            \else | call SingleCompile#CompileRun(<q-args>) | endif
command -nargs=* SingleCompile       
            \if <q-args> == '' | call SingleCompile#Compile() |
            \else | call SingleCompile#Compile(<q-args>) | endif
command -nargs=* SingleCompileRun    
            \if <q-args> == '' | call SingleCompile#CompileRun() | 
            \else | call SingleCompile#CompileRun(<q-args>) | endif
command -nargs=+ SCCompileAF    
            \call SingleCompile#Compile('AdditionalFlags', <q-args>)
command -nargs=+ SCCompileRunAF    
            \call SingleCompile#CompileRun('AdditionalFlags', <q-args>)
command SCChooseCompiler call SingleCompile#ChooseCompiler(&filetype)
command SCChooseInterpreter call SingleCompile#ChooseCompiler(&filetype)

" menus {{{1

if !exists('g:SingleCompile_menumode')
    let g:SingleCompile_menumode = 1
endif

if has('gui_running') && has('menu')
    if g:SingleCompile_menumode == 1
        nnoremenu Plugin.SingleCompile.&Compile<tab>:SCCompile :SCCompile<cr>
        nnoremenu Plugin.SingleCompile.Compile\ and\ &Run<tab>:SCCompileRun
                    \ :SCCompileRun<cr>
        nnoremenu Plugin.SingleCompile.C&hoose\ Compiler<tab>:SCChooseCompiler
                    \ :SCChooseCompiler<cr>
        inoremenu Plugin.SingleCompile.&Compile<tab>:SCCompile
                    \ <C-O>:SCCompile<cr>
        inoremenu Plugin.SingleCompile.Compile\ and\ &Run<tab>:SCCompileRun
                    \ <C-O>:SCCompileRun<cr>
        inoremenu Plugin.SingleCompile.C&hoose\ Compiler<tab>:SCChooseCompiler
                    \ <C-O>:SCChooseCompiler<cr>
        vnoremenu Plugin.SingleCompile.&Compile<tab>:SCCompile
                    \ <Esc>:SCCompile<cr>
        vnoremenu Plugin.SingleCompile.Compile\ and\ &Run<tab>:SCCompileRun
                    \ <Esc>:SCCompileRun<cr>
        vnoremenu Plugin.SingleCompile.C&hoose\ Compiler<tab>:SCChooseCompiler
                    \ <Esc>:SCChooseCompiler<cr>
    elseif g:SingleCompile_menumode == 2
        nnoremenu SingleCompile.&Compile<tab>:SCCompile :SCCompile<cr>
        nnoremenu SingleCompile.Compile\ and\ &Run<tab>:SCCompileRun
                    \ :SCCompileRun<cr>
        nnoremenu SingleCompile.C&hoose\ Compiler<tab>:SCChooseCompiler
                    \ :SCChooseCompiler<cr>
        inoremenu SingleCompile.&Compile<tab>:SCCompile <C-O>:SCCompile<cr>
        inoremenu SingleCompile.Compile\ and\ &Run<tab>:SCCompileRun
                    \ <C-O>:SCCompileRun<cr>
        inoremenu SingleCompile.C&hoose\ Compiler<tab>:SCChooseCompiler
                    \ <C-O>:SCChooseCompiler<cr>
        vnoremenu SingleCompile.&Compile<tab>:SCCompile <Esc>:SCCompile<cr>
        vnoremenu SingleCompile.Compile\ and\ &Run<tab>:SCCompileRun
                    \ <Esc>:SCCompileRun<cr>
        vnoremenu SingleCompile.C&hoose\ Compiler<tab>:SCChooseCompiler
                    \ <Esc>:SCChooseCompiler<cr>
    endif
endif

" }}}


" vim-addon-actions support (activate this addon after vim-addon-actions) {{{
" eg call scriptmanager#Activate(["vim-addon-actions","SingleCompile"])
if exists('g:vim_actions')
    for cmd in ['SingleCompile','SingleCompileRun']
        call actions#AddAction('run '.cmd, 
                    \{'action': funcref#Function('return '.string([cmd]))})
    endfor
endif
"}}}

let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim:fdm=marker et ts=4 tw=78 sw=4
