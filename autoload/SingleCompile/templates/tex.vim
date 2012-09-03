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
    call SingleCompile#SetCompilerTemplate('tex', 'pdflatex', 'pdfLaTeX',
                \'pdflatex', '-interaction=nonstopmode',
                \ SingleCompile#GetDefaultOpenCommand() .
                \ ' "$(FILE_TITLE)$.pdf"')
    call SingleCompile#SetPriority('tex', 'pdflatex', 50)
    call SingleCompile#SetCompilerTemplate('tex', 'latex', 'LaTeX',
                \'latex', '-interaction=nonstopmode',
                \ SingleCompile#GetDefaultOpenCommand() .
                \ ' "$(FILE_TITLE)$.dvi"')
    call SingleCompile#SetPriority('tex', 'latex', 80)

	" latexmk which automatically calls pdflatex, but runs it multiple times
	" to that all references are sorted out correctly.
	call SingleCompile#SetCompilerTemplate('tex', 'latexmk', 'latexmk',
				\ 'latexmk', '-pdf',
				\ SingleCompile#GetDefaultOpenCommand() .
                \ ' "$(FILE_TITLE)$.pdf"')
    call SingleCompile#SetPriority('tex', 'latexmk', 30)
endfunction

"vim703: cc=78
"vim: et ts=4 tw=78 sw=4
