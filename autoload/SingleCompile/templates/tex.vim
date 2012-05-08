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

function! SingleCompile#templates#tex#Initialize()
    if has('win32') || has('macunix')
        call SingleCompile#SetCompilerTemplate('tex', 'pdflatex', 'pdfLaTeX',
                    \'pdflatex', '-interaction=nonstopmode',
                    \'open "$(FILE_TITLE)$.pdf"')
    elseif has('unix')
        call SingleCompile#SetCompilerTemplate('tex', 'pdflatex', 'pdfLaTeX',
                    \'pdflatex', '-interaction=nonstopmode',
                    \'xdg-open "$(FILE_TITLE)$.pdf"')
    endif
    call SingleCompile#SetPriority('tex', 'pdflatex', 50)
    if has('win32') || has('macunix')
        call SingleCompile#SetCompilerTemplate('tex', 'latex', 'LaTeX',
                    \'latex', '-interaction=nonstopmode',
                    \'open "$(FILE_TITLE)$.dvi"')
    elseif has('unix')
        call SingleCompile#SetCompilerTemplate('tex', 'latex', 'LaTeX',
                    \'latex', '-interaction=nonstopmode',
                    \'xdg-open "$(FILE_TITLE)$.dvi"')
    endif
    call SingleCompile#SetPriority('tex', 'latex', 80)
endfunction
