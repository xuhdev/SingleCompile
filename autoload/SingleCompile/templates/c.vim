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

function! SingleCompile#templates#c#Initialize()
    call SingleCompile#SetCompilerTemplate('c', 'open-watcom',
                \'Open Watcom C/C++32 Compiler', 'wcl386', '',
                \g:SingleCompile_common_run_command, function('SingleCompile#DetectWatcom'))
    call SingleCompile#SetCompilerTemplateByDict('c', 'open-watcom', {
                \ 'pre-do'  : function('SingleCompile#PredoWatcom'),
                \ 'post-do' : function('SingleCompile#PostdoWatcom'),
                \ 'out-file': g:SingleCompile_common_out_file
                \})
    if has('win32')
        call SingleCompile#SetCompilerTemplate('c', 'msvc',
                    \'Microsoft Visual C++ (In PATH)', 'cl',
                    \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('c', 'msvc', g:SingleCompile_common_out_file)
        call SingleCompile#SetCompilerTemplate('c', 'msvc80',
                    \ 'Microsoft Visual C++ 2005 (8.0)', 'cl80',
                    \ '-o $(FILE_TITLE)$', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('c', 'msvc80', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 15,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('c', 'msvc90',
                    \ 'Microsoft Visual C++ 2008 (9.0)', 'cl90',
                    \ ' ', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('c', 'msvc90', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 14,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('c', 'msvc100',
                    \ 'Microsoft Visual C++ 2010 (10.0)', 'cl100',
                    \ ' ', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('c', 'msvc100', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 13,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('c', 'msvc110',
                    \ 'Microsoft Visual C++ 2012 (11.0)', 'cl110',
                    \ ' ', g:SingleCompile_common_run_command,
                    \ function('SingleCompile#DetectMicrosoftVC'))
        call SingleCompile#SetCompilerTemplateByDict('c', 'msvc110', {
                    \ 'pre-do' : function('SingleCompile#PredoMicrosoftVC'),
                    \ 'post-do' : function('SingleCompile#PostdoMicrosoftVC'),
                    \ 'out-file' : g:SingleCompile_common_out_file,
                    \ 'priority' : 12,
                    \ 'vim-compiler' : 'msvc'})
        call SingleCompile#SetCompilerTemplate('c', 'bcc',
                    \'Borland C++ Builder', 'bcc32',
                    \'-o$(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('c', 'bcc', g:SingleCompile_common_out_file)
    endif
    call SingleCompile#SetCompilerTemplate('c', 'gcc', 'GNU C Compiler',
                \'gcc', '-g -o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('c', 'gcc', {
                \ 'pre-do'  : function('SingleCompile#PredoGcc'),
                \ 'priority' : 20,
                \ 'out-file': g:SingleCompile_common_out_file
                \})
    call SingleCompile#SetCompilerTemplate('c', 'icc',
                \'Intel C++ Compiler', 'icc', '-o $(FILE_TITLE)$',
                \g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('c', 'icc', g:SingleCompile_common_out_file)
    if has('win32')
        call SingleCompile#SetCompilerTemplate('c', 'lcc',
                    \'Little C Compiler', 'lc',
                    \'$(FILE_TITLE)$ -o "$(FILE_TITLE)$.exe"',
                    \g:SingleCompile_common_run_command)
    else
        call SingleCompile#SetCompilerTemplate('c', 'lcc',
                    \'Little C Compiler', 'lc',
                    \'$(FILE_TITLE)$ -o $(FILE_TITLE)$',
                    \g:SingleCompile_common_run_command)
    endif
    call SingleCompile#SetOutfile('c', 'lcc', g:SingleCompile_common_out_file)
    call SingleCompile#SetCompilerTemplate('c', 'pcc',
                \'Portable C Compiler', 'pcc', '-o $(FILE_TITLE)$',
                \g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('c', 'pcc', g:SingleCompile_common_out_file)
    call SingleCompile#SetCompilerTemplate('c', 'tcc', 'Tiny C Compiler',
                \'tcc', '-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('c', 'tcc', g:SingleCompile_common_out_file)
    call SingleCompile#SetCompilerTemplate('c', 'tcc-run',
                \'Tiny C Compiler with "-run" Flag', 'tcc', '-run', '')
    call SingleCompile#SetPriority('c', 'tcc-run', 140)
    call SingleCompile#SetCompilerTemplate('c', 'ch',
                \'SoftIntegration Ch', 'ch', '', '')
    call SingleCompile#SetPriority('c', 'ch', 130)
    call SingleCompile#SetCompilerTemplate('c', 'clang',
                \ 'the Clang C and Objective-C compiler', 'clang',
                \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('c', 'clang', {
                \ 'pre-do'  : function('SingleCompile#PredoClang'),
                \ 'out-file': g:SingleCompile_common_out_file
                \})
    if has('unix')
        call SingleCompile#SetCompilerTemplate('c', 'cc',
                    \'UNIX C Compiler', 'cc', '-o $(FILE_TITLE)$',
                    \g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('c', 'cc', g:SingleCompile_common_out_file)
        call SingleCompile#SetCompilerTemplate('c', 'sol-studio',
                    \'Sun C Compiler (Sun Solaris Studio)', 'suncc',
                    \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetCompilerTemplateByDict('c', 'sol-studio', {
                    \ 'pre-do'  : function('SingleCompile#PredoSolStudioC'),
                    \ 'out-file': g:SingleCompile_common_out_file
                    \})
        call SingleCompile#SetCompilerTemplate('c', 'open64',
                    \'Open64 C Compiler', 'opencc', '-o $(FILE_TITLE)$',
                    \g:SingleCompile_common_run_command)
    endif
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
