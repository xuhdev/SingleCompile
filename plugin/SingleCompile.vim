" Copyright (C) 2010-2014 Hong Xu

" This file is part of SingleCompile.

" SingleCompile is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.

" SingleCompile is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.

" You should have received a copy of the GNU General Public License
" along with SingleCompile.  If not, see <http://www.gnu.org/licenses/>.

" File: plugin/SingleCompile.vim
" GetLatestVimScripts: 3115 1 SingleCompile.zip
" version 2.12.0
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
            \ if <q-args> == '' | call SingleCompile#Compile() |
            \ else | call SingleCompile#Compile(<q-args>) | endif
command -nargs=* SCCompileRun
            \ if <q-args> == '' | call SingleCompile#CompileRun() |
            \ else | call SingleCompile#CompileRun(<q-args>) | endif
command -nargs=* SCCompileRunAsync
            \ if <q-args> == '' | call SingleCompile#CompileRunAsync() |
            \ else | call SingleCompile#CompileRunAsync(<q-args>) | endif
command -nargs=* SingleCompile
            \ if <q-args> == '' | call SingleCompile#Compile() |
            \ else | call SingleCompile#Compile(<q-args>) | endif
command -nargs=* SingleCompileRun
            \ if <q-args> == '' | call SingleCompile#CompileRun() |
            \ else | call SingleCompile#CompileRun(<q-args>) | endif
command -nargs=+ SCCompileAF
            \ call SingleCompile#Compile('AdditionalFlags', <q-args>)
command -nargs=+ SCCompileRunAF
            \ call SingleCompile#CompileRun('AdditionalFlags', <q-args>)
command -nargs=+ SCCompileRunAsyncAF
            \ call SingleCompile#CompileRunAsync('AdditionalFlags', <q-args>)
command SCIsRunningAsync
            \ if SingleCompileAsync#IsRunning() == 1 |
            \ echo 'The background process is running.' |
            \ else |
            \ echo 'The background process is not running.' |
            \ endif
command SCTerminateAsync
            \ if SingleCompileAsync#Terminate() |
            \ echohl ErrorMsg |
            \ echo 'Failed to terminate the background process!' |
            \ echohl None |
            \ else |
            \ echo 'Background process terminated.' |
            \ endif
command SCChooseCompiler call SingleCompile#ChooseCompiler(&filetype)
command SCChooseInterpreter call SingleCompile#ChooseCompiler(&filetype)
command SCViewResult call SingleCompile#ViewResult(0)
command SCViewResultAsync call SingleCompile#ViewResult(1)

" menus {{{1

if !exists('g:SingleCompile_menumode')
    let g:SingleCompile_menumode = 1
endif

if has('gui_running') && has('menu')
    if g:SingleCompile_menumode == 1
        let s:menu_root = 'Plugin.SingleCompile'
    elseif g:SingleCompile_menumode == 2
        let s:menu_root = 'SingleCompile'
    endif

    " if g:SingleCompile_menumode is not 1 or 2, then we don't need to create
    " menu
    if g:SingleCompile_menumode == 1 || g:SingleCompile_menumode == 2
        for s:menu_textcmd in [
                    \ '&Compile<tab>:SCCompile '.
                    \ ':SCCompile<cr>',
                    \
                    \ 'Compile\ and\ &Run<tab>:SCCompileRun '.
                    \ ':SCCompileRun<cr>',
                    \
                    \ 'Compile\ and\ Run &Asynchronously'.
                    \ '<tab>:SCCompileRunAsync'.
                    \ ':SCCompileRunAsync<cr>',
                    \
                    \ 'C&hoose\ Compiler<tab>:SCChooseCompiler '.
                    \ ':SCChooseCompiler<cr>',
                    \
                    \ '&View\ Result<tab>:SCViewResult '.
                    \ ':SCViewResult<cr>',
                    \
                    \ 'V&iew\ Result\ of\ Asynchronous\ Running'.
                    \ '<tab>:SCViewResultAsync '.
                    \ ':SCViewResultAsync<cr>',
                    \
                    \ '&Terminate\ the\ Background\ Asynchronous\ Process'.
                    \ '<tab>:SCTerminateAsync '.
                    \ ':SCTerminateAsync<cr>'
                    \ ]

            for s:menu_type in ['nnoremenu', 'inoremenu', 'vnoremenu']
                exec s:menu_type.' '.s:menu_root.'.'.s:menu_textcmd
            endfor
        endfor

        unlet! s:menu_root
        unlet! s:menu_type
        unlet! s:menu_textcmd
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

" vim703: cc=78
" vim:fdm=marker et ts=4 tw=78 sw=4
