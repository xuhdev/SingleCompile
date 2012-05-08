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

function! s:DetectGmake(not_used_arg)
    let l:make_command = s:DetectCompilerGenerally('gmake')
    if l:make_command != 0
        return l:make_command
    endif

    let l:make_command = s:DetectCompilerGenerally('make')
    if l:make_command != 0
        return l:make_command
    endif

    return 0
endfunction

function! SingleCompile#templates#make#Initialize()
    call SingleCompile#SetCompilerTemplate('make', 'gmake', 'GNU Make',
                \'gmake', '-f', '', function('s:DetectGmake'))
    call SingleCompile#SetCompilerTemplate('make', 'mingw32-make',
                \'MinGW32 Make', 'mingw32-make', '-f', '')
    if has('win32')
        call SingleCompile#SetCompilerTemplate('make', 'nmake',
                    \'Microsoft Program Maintenance Utility', 'nmake',
                    \'-f', '')
    endif
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
