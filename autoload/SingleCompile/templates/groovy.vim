" Copyright (C) 2010-2017 white Jia

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
    call SingleCompile#SetCompilerTemplate('groovy', 'groovy', 'apache groovy compiler',
                \'groovy', '', '')
    call SingleCompile#SetVimCompiler('groovy', 'apache', 'groovyc')
    call SingleCompile#SetPriority('groovy', 'apache', 70)
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
