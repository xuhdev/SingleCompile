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

function! SingleCompile#templates#fortran#Initialize()
    call SingleCompile#SetCompilerTemplate('fortran', 'gfortran',
                \'GNU Fortran Compiler', 'gfortran',
                \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('fortran', 'gfortran',
                \g:SingleCompile_common_out_file)
    call SingleCompile#SetPriority('fortran', 'gfortran', 70)
    call SingleCompile#SetCompilerTemplate('fortran', 'g95',
                \'G95', 'g95', '-o $(FILE_TITLE)$'.SingleCompile#GetExecutableSuffix(),
                \g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('fortran', 'g95', g:SingleCompile_common_out_file)
    if has('unix')
        call SingleCompile#SetCompilerTemplate('fortran',
                    \'sol-studio-f77',
                    \'Sun Fortran 77 Compiler (Sun Solaris Studio)',
                    \'sunf77', '-o $(FILE_TITLE)$',
                    \g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('fortran', 'sol-studio-f77',
                    \g:SingleCompile_common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran',
                    \'sol-studio-f90',
                    \'Sun Fortran 90 Compiler (Sun Solaris Studio)',
                    \'sunf90', '-o $(FILE_TITLE)$',
                    \g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('fortran', 'sol-studio-f90',
                    \g:SingleCompile_common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran',
                    \'sol-studio-f95',
                    \'Sun Fortran 95 Compiler (Sun Solaris Studio)',
                    \'sunf95', '-o $(FILE_TITLE)$',
                    \g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('fortran', 'sol-studio-f95',
                    \g:SingleCompile_common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran', 'open64-f90',
                    \'Open64 Fortran 90 Compiler', 'openf90',
                    \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('fortran', 'open64-f90',
                    \g:SingleCompile_common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran', 'open64-f95',
                    \'Open64 Fortran 95 Compiler', 'openf95',
                    \'-o $(FILE_TITLE)$', g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('fortran', 'open64-f95',
                    \g:SingleCompile_common_out_file)
    endif
    if has('win32')
        call SingleCompile#SetCompilerTemplate('fortran', 'ftn95',
                    \'Silverfrost FTN95', 'ftn95', '$(FILE_NAME)$ /LINK',
                    \g:SingleCompile_common_run_command)
        call SingleCompile#SetOutfile('fortran', 'ftn95',
                    \g:SingleCompile_common_out_file)
    endif
    call SingleCompile#SetCompilerTemplate('fortran', 'g77',
                \'GNU Fortran 77 Compiler', 'g77', '-o $(FILE_TITLE)$',
                \g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('fortran', 'g77', g:SingleCompile_common_out_file)
    call SingleCompile#SetVimCompiler('fortran', 'g77', 'fortran_g77')
    call SingleCompile#SetCompilerTemplate('fortran', 'ifort',
                \'Intel Fortran Compiler', 'ifort', '-o $(FILE_TITLE)$',
                \g:SingleCompile_common_run_command)
    call SingleCompile#SetOutfile('fortran', 'ifort', g:SingleCompile_common_out_file)
    call SingleCompile#SetPriority('fortran', 'ifort', 80)
    call SingleCompile#SetCompilerTemplate('fortran', 'open-watcom',
                \'Open Watcom Fortran 77/32 Compiler', 'wfl386', '',
                \g:SingleCompile_common_run_command, function('SingleCompile#DetectWatcom'))
    call SingleCompile#SetCompilerTemplateByDict('fortran', 'open-watcom',
                \{
                \ 'pre-do'  : function('SingleCompile#PredoWatcom'),
                \ 'post-do' : function('SingleCompile#PostdoWatcom'),
                \ 'out-file': g:SingleCompile_common_out_file
                \})
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
