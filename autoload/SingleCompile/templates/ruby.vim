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

function! SingleCompile#templates#ruby#Initialize()
    call SingleCompile#SetCompilerTemplate('ruby', 'ruby',
                \'Ruby Interpreter', 'ruby', '', '')
    call SingleCompile#SetPriority('ruby', 'ruby', 50)

    call SingleCompile#SetCompilerTemplate('ruby', 'jruby',
                \'Ruby JVM Interpreter (default Ruby version)', 'jruby', '', '')
    call SingleCompile#SetPriority('ruby', 'jruby', 55)

    call SingleCompile#SetCompilerTemplate('ruby', 'jruby1.8',
                \'Ruby JVM Interpreter (1.8)', 'jruby', '--1.8', '')
    call SingleCompile#SetPriority('ruby', 'jruby1.8', 80)

    call SingleCompile#SetCompilerTemplate('ruby', 'jruby1.9',
                \'Ruby JVM Interpreter (1.9)', 'jruby', '--1.9', '')
    call SingleCompile#SetPriority('ruby', 'jruby1.9', 60)

    call SingleCompile#SetCompilerTemplate('ruby', 'jruby2.0',
                \'Ruby JVM Interpreter (2.0)', 'jruby', '--2.0', '')
    call SingleCompile#SetPriority('ruby', 'jruby2.0', 70)

endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
