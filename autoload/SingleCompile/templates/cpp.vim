" Copyright (C) 2010-2012 Hong Xu

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

" check doc/SingleCompile.txt for more information

function! SingleCompile#templates#cpp#Initialize()
    call SingleCompile#SetCompilerTemplate('cpp', 'open-watcom',
                \'Open Watcom C/C++32 Compiler',
                \ 'wcl386', '', g:SingleCompile_common_run_command,
                \ function('SingleCompile#DetectWatcom'))
    call SingleCompile#SetCompilerTemplateByDict('cpp', 'open-watcom', {
                \ 'pre-do'  : function('SingleCompile#PredoWatcom'),
                \ 'post-do' : function('SingleCompile#PostdoWatcom'),
                \ 'out-file': g:SingleCompile_common_out_file
                \})
    if has('win32')
        call SingleCompile#SetCompilerTemplate('cpp', 'msvc',
                    \'Microsoft Visual C++ (In PATH)', 'cl',
                    \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('cpp', 'msvc', g:SingleCompile_common_out_file)
        call SingleCompile#SetCompilerTemplate('cpp', 'msvc80',
                    \ 'Microsoft Visual C++ 2005 (8.0)', 'cl80',
                    \ '-o $(FILE_TITLE)$', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('cpp', 'msvc80', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 15,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('cpp', 'msvc90',
                    \ 'Microsoft Visual C++ 2008 (9.0)', 'cl90',
                    \ '/EHsc', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('cpp', 'msvc90', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 14,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('cpp', 'msvc100',
                    \ 'Microsoft Visual C++ 2010 (10.0)', 'cl100',
                    \ '/EHsc', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('cpp', 'msvc100', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 13,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('cpp', 'msvc110',
                    \ 'Microsoft Visual C++ 2012 (11.0)', 'cl110',
                    \ '/EHsc', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('cpp', 'msvc110', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 12,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('cpp', 'bcc',
                    \'Borland C++ Builder','bcc32', '-o$(FILE_TITLE)$',
                    \g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('cpp', 'bcc', g:SingleCompile_common_out_file)
    endif
    call SingleCompile#SetCompilerTemplate('cpp', 'g++',
                \'GNU C++ Compiler', 'g++', '-g -o $(FILE_TITLE)$',
                \g:SingleCompile_common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('cpp', 'g++', {
                \ 'pre-do'  : function('SingleCompile#PredoGcc'),
                \ 'out-file': g:SingleCompile_common_out_file,
                \ 'priority' : 20,
                \ 'vim-compiler': 'gcc'
                \})
    call SingleCompile#SetCompilerTemplate('cpp', 'icc',
                \'Intel C++ Compiler', 'icc', '-o $(FILE_TITLE)$',
                \g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('cpp', 'icc', g:SingleCompile_common_out_file)
    call SingleCompile#SetCompilerTemplate('cpp', 'ch',
                \'SoftIntegration Ch', 'ch', '', '')
    call SingleCompile#SetPriority('cpp', 'ch', 130)
    call SingleCompile#SetCompilerTemplate('cpp', 'clang',
                \ 'the Clang C and Objective-C compiler',
                \'clang++', '-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('cpp', 'clang', {
                \ 'pre-do'  : function('SingleCompile#PredoClang'),
                \ 'out-file': g:SingleCompile_common_out_file,
                \ 'vim-compiler': 'clang'
                \})
    if has('unix')
        call SingleCompile#SetCompilerTemplate('cpp', 'sol-studio',
                    \'Sun C++ Compiler (Sun Solaris Studio)', 'sunCC',
                    \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetCompilerTemplateByDict('cpp', 'sol-studio',{
                    \ 'pre-do'  : function('SingleCompile#PredoSolStudioC'),
                    \ 'out-file': g:SingleCompile_common_out_file
                    \})
        call SingleCompile#SetCompilerTemplate('cpp', 'open64',
                    \'Open64 C++ Compiler', 'openCC',
                    \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('cpp', 'open64', g:SingleCompile_common_out_file)
    endif
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
