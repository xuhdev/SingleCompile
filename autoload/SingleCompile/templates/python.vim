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

function! SingleCompile#templates#python#Initialize()
    call SingleCompile#SetCompilerTemplate('python', 'python', 'CPython (Usually the system default version. Can be Python 2 or 3.)',
                \'python', '', '')
    call SingleCompile#SetPriority('python', 'python', 50)
    call SingleCompile#SetCompilerTemplate('python', 'ironpython',
                \'IronPython', 'ipy', '', '')
    call SingleCompile#SetCompilerTemplate('python', 'jython', 'Jython',
                \'jython', '', '')
    call SingleCompile#SetCompilerTemplate('python', 'pypy', 'PyPy',
                \'pypy', '', '')
    call SingleCompile#SetPriority('python', 'pypy', 110)
    call SingleCompile#SetCompilerTemplate('python', 'python2',
                \'CPython 2', 'python2', '', '')
    call SingleCompile#SetPriority('python', 'python', 60)
    call SingleCompile#SetCompilerTemplate('python', 'python3',
                \'CPython 3', 'python3', '', '')
    call SingleCompile#SetPriority('python', 'python3', 120)
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
