" Copyright (C) 2013 PAN, Myautsai

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

function! SingleCompile#templates#matlab#Initialize()
    call SingleCompile#SetCompilerTemplate('matlab', 'matlab', 'MathWorks MATLAB',
                \'matlab', '-nodisplay -nosplash -r $(FILE_TITLE)$,exit', '')
    call SingleCompile#SetPriority('matlab', 'matlab', 50)
    call SingleCompile#SetCompilerTemplate('matlab', 'octave', 'GNU Octave',
                \'octave', '', '')
    call SingleCompile#SetPriority('matlab', 'octave', 60)
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
