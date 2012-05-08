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

function! SingleCompile#templates#xhtml#Initialize()
    call SingleCompile#SetCompilerTemplate('xhtml', 'firefox',
                \'Mozilla Firefox', 'firefox', '', '')
    call SingleCompile#SetPriority('xhtml', 'firefox', 60)
    call SingleCompile#SetCompilerTemplate('xhtml', 'chrome',
                \'Google Chrome', 'google-chrome', '', '')
    call SingleCompile#SetPriority('xhtml', 'chrome', 70)
    call SingleCompile#SetCompilerTemplate('xhtml', 'chromium',
                \'Chromium', 'chromium', '', '')
    call SingleCompile#SetPriority('xhtml', 'chromium', 71)
    call SingleCompile#SetCompilerTemplate('xhtml', 'opera',
                \'Opera', 'opera', '', '')
    call SingleCompile#SetPriority('xhtml', 'opera', 80)
    call SingleCompile#SetCompilerTemplate('xhtml', 'konqueror',
                \'Konqueror', 'konqueror', '', '')
    call SingleCompile#SetCompilerTemplate('xhtml', 'arora',
                \'Arora', 'arora', '', '')
    call SingleCompile#SetCompilerTemplate('xhtml', 'epiphany',
                \'Epiphany', 'epiphany', '', '')
    if has('win32')
        call SingleCompile#SetCompilerTemplate('xhtml', 'ie',
                    \'Microsoft Internet Explorer', 'iexplore', '', '',
                    \function('SingleCompile#DetectIe'))
        call SingleCompile#SetPriority('xhtml', 'ie', 50)
    else
        call SingleCompile#SetCompilerTemplate('xhtml', 'ie',
                    \'Microsoft Internet Explorer', 'iexplore', '', '')
    endif
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
