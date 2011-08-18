" File: autoload/SingleCompile.vim
" Version: 2.8.7
" check doc/SingleCompile.txt for more information


let s:saved_cpo = &cpo
set cpo&vim


" varibles {{{1
" the two dicts to store the compiler template
let g:SingleCompile_templates = {}
let s:CompilerTemplate = {}

" is template initialize
let s:Initialized = 0

" Chars to escape for ':lcd' command
if has('win32')
    let s:CharsEscape = '" '
else
    let s:CharsEscape = '" \'
endif

" executable suffix
if has('win32')
    let s:ExecutableSuffix = '.exe'
else
    let s:ExecutableSuffix = ''
endif

" seperator in the environment varibles
if has('win32')
    let s:EnvSeperator = ';'
else
    let s:EnvSeperator = ':'
endif

if has('win32')
    let s:PathSeperator = '\'
else
    let s:PathSeperator = '/'
endif

" the path of file where the output running result is stored
let s:run_result_tempfile = ''



function! SingleCompile#GetVersion() " get the script version {{{1
    return 287
endfunction

" util {{{1
function! s:GetShellPipe(tee_used) " {{{2
    " get the shell pipe command according to it's platform. If a:tee_used is
    " set to nonzero, then the shell pipe contains "tee", otherwise "tee"
    " wouldn't be contained in the return value.

    if has('unix')
        let l:cur_shell = strpart(&shell, strridx(&shell, '/') + 1)

        if l:cur_shell =~ '^csh' || l:cur_shell =~ '^tcsh' 
            if a:tee_used
                return '|& tee'
            else
                return '>&'
            endif
        elseif l:cur_shell =~ '^sh' ||
                    \l:cur_shell =~ '^bash' ||
                    \l:cur_shell =~ '^ksh' ||
                    \l:cur_shell =~ '^mksh' ||
                    \l:cur_shell =~ '^pdksh' ||
                    \l:cur_shell =~ '^zsh'
            if a:tee_used
                return '2>&1| tee'
            else
                return '>%s 2>&1'
            endif
        else
            if a:tee_used
                return '| tee'
            else
                return '>'
            endif
        endif
    elseif has('win32')
        if executable('tee') && a:tee_used
            return '2>&1 | tee'
        else
            return '>%s 2>&1'
        endif
    endif

endfunction
function! s:Expand(str, ...) " expand the string{{{2
    " the second argument is optional. If it is given and it is zero, then
    " we thought we don't need single quote.

    let l:double_quote_needed = 1
    if a:0 > 1
        call s:ShowMessage('s:Expand argument error.')
        return ''
    elseif a:0 == 1
        if !a:1
            let l:double_quote_needed = 0
        endif
    endif

    let l:rep_dict = {
                \'\$(FILE_NAME)\$': '%',
                \'\$(FILE_TITLE)\$': '%:r',
                \'\$(FILE_PATH)\$': '%:p',
                \'\$(FILE_EXEC)\$': '%:p'}

    let l:rep_dict_suffix = {
                \'\$(FILE_NAME)\$': '',
                \'\$(FILE_TITLE)\$': '',
                \'\$(FILE_PATH)\$': ''}

    if has('win32')
        let l:rep_dict_suffix['\$(FILE_EXEC)\$'] = '.exe'
    elseif has('unix')
        let l:rep_dict_suffix['\$(FILE_EXEC)\$'] = ''
    endif


    let l:str = a:str
    for one_key in keys(l:rep_dict)
        let l:rep_string = expand(l:rep_dict[one_key]).
                    \l:rep_dict_suffix[one_key]

        " on win32, replace the backslash with '/'
        if has('win32')
            let l:rep_string = substitute(l:rep_string, '/', '\\', 'g')
        endif

        let l:rep_string = escape(l:rep_string, '\')
        if l:double_quote_needed && match(l:rep_string, ' ') != -1
            let l:rep_string = "'".l:rep_string."'"
        endif
        let l:str = substitute(l:str, one_key, l:rep_string, 'g')
    endfor

    return l:str
endfunction

function! s:RunAsyncWithMessage(run_cmd) " {{{2
    " run a command and display messages that we need to

    let l:async_run_res = SingleCompileAsync#Run(a:run_cmd)

    if l:async_run_res != 0
        call s:ShowMessage(
                    \"Fail to run the command '".
                    \a:run_cmd."'. Error code: ".l:async_run_res)

        if l:async_run_res == 1
            call s:ShowMessage(
                        \'There is already an existing process '.
                        \'running in background.')
        endif

        return 1
    endif

    return 0
endfunction

" pre-do functions {{{1

function! s:AddLmIfMathH(compiling_info) " {{{2 
    " add -lm flag if math.h is included

    " if we find '#include <math.h>' in the file, then add '-lm' flag
    if match(getline(1, '$'), '^[ \t]*#[ \t]*include[ \t]*["<]math.h[">][ \t]*$') 
                \!= -1
        let l:new_comp_info = a:compiling_info
        let l:new_comp_info['args'] = '-lm '.l:new_comp_info['args']
        return l:new_comp_info
    endif

    return a:compiling_info
endfunction

function! s:PredoWatcom(compiling_info) " watcom pre-do {{{2
    let s:old_path = $PATH
    let $PATH = $WATCOM.s:PathSeperator.'binnt'.s:EnvSeperator.
                \$WATCOM.s:PathSeperator.'binw'.s:EnvSeperator.
                \$PATH
    return a:compiling_info
endfunction

function! s:PredoGcc(compiling_info) " gcc pre-do {{{2
    if has('unix')
        return s:AddLmIfMathH(a:compiling_info)
    else
        return a:compiling_info
    endif
endfunction

function! s:PredoSolStudioC(compiling_info) " solaris studio C/C++ pre-do {{{2
    return s:AddLmIfMathH(a:compiling_info)
endfunction

function! s:PredoClang(compiling_info) " clang Predo {{{2
    if has('unix')
        return s:AddLmIfMathH(a:compiling_info)
    else
        return a:compiling_info
    endif
endfunction

" post-do functions {{{1
function! s:PostdoWatcom(compiling_info) " watcom pre-do {{{2
    let $PATH = s:old_path
    return a:compiling_info
endfunction

" compiler detect functions {{{1
function! s:DetectCompilerGenerally(compiling_command) " {{{2
    " the general function of compiler detection. The principle is to search
    " the environment varible PATH and some special directory

    if has('unix')
        let l:list_to_detect = [s:Expand(expand(a:compiling_command)),
                    \s:Expand(expand('~/bin/'.a:compiling_command)),
                    \s:Expand(expand('/usr/local/bin/'.a:compiling_command)),
                    \s:Expand(expand('/usr/bin/'.a:compiling_command)),
                    \s:Expand(expand('/bin/'.a:compiling_command))
                    \]
    else
        let l:list_to_detect = [s:Expand(expand(a:compiling_command))]
    endif

    for cmd in l:list_to_detect
        if executable(cmd) == 1
            return cmd
        endif
    endfor

    return 0
endfunction

function! SingleCompile#DetectCompilerGenerally(compiling_command)
    return s:DetectCompilerGenerally(a:compiling_command)
endfunction

function! s:DetectWatcom(compiling_command) " {{{2
    let l:watcom_command =
                \s:DetectCompilerGenerally(a:compiling_command)
    if l:watcom_command != 0
        return l:watcom_command
    endif

    if $WATCOM != ''
        return $WATCOM.'\binnt\'.a:compiling_command
    endif
endfunction

function! s:DetectIe(not_used_arg) " {{{2
    if executable('iexplore')
        return 'iexplore'
    endif

    if has('win32')
        let iepath = $PROGRAMFILES . '\Internet Explorer\iexplore.exe'
        if executable(iepath)
            return "\"".iepath."\""
        endif
    endif
endfunction

function! s:DetectDosbatch(not_used_arg) " {{{2
    " always return an empty string, because dosbatch is always available on
    " Windows.
    return ''
endfunction

function! s:DetectGmake(not_used_arg) " {{{2
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

function! s:Initialize() "{{{1

    if s:Initialized == 0
        let s:Initialized = 1
    else
        return
    endif

    if !exists('g:SingleCompile_alwayscompile') ||
                \type(g:SingleCompile_alwayscompile) != type(0)
        unlet! g:SingleCompile_alwayscompile
        let g:SingleCompile_alwayscompile = 1
    endif

    if !exists('g:SingleCompile_asyncrunmode') ||
                \type(g:SingleCompile_asyncrunmode) != type('')
        unlet! g:SingleCompile_asyncrunmode
        let g:SingleCompile_asyncrunmode = 'auto'
    endif

    if !exists('g:SingleCompile_autowrite') ||
                \type(g:SingleCompile_autowrite) != type(0)
        unlet! g:SingleCompile_autowrite
        let g:SingleCompile_autowrite = 1
    endif

    if !exists('g:SingleCompile_resultheight') ||
                \type(g:SingleCompile_resultheight) != type(0) ||
                \g:SingleCompile_resultheight <= 0
        unlet! g:SingleCompile_resultheight
        let g:SingleCompile_resultheight = 5
    endif

    if !exists('g:SingleCompile_showquickfixiferror') ||
                \type(g:SingleCompile_showquickfixiferror) != type(0)
        unlet! g:SingleCompile_showquickfixiferror
        let g:SingleCompile_showquickfixiferror = 0
    endif

    if !exists('g:SingleCompile_showresultafterrun') ||
                \type(g:SingleCompile_showresultafterrun) != type(0)
        unlet! g:SingleCompile_showresultafterrun
        let g:SingleCompile_showresultafterrun = 0
    endif

    if !exists('g:SingleCompile_usedialog') ||
                \type(g:SingleCompile_usedialog) != type(0)
        unlet! g:SingleCompile_usedialog
        let g:SingleCompile_usedialog = 0
    endif

    if !exists('g:SingleCompile_usequickfix') ||
                \type(g:SingleCompile_usequickfix) != type(0)
        unlet! g:SingleCompile_usequickfix
        let g:SingleCompile_usequickfix = 1
    endif


    " Initialize async mode
    if g:SingleCompile_asyncrunmode !=? 'none'
        let l:async_init_res = SingleCompileAsync#Initialize(
                    \g:SingleCompile_asyncrunmode)

        if type(l:async_init_res) == type('')
            call s:ShowMessage(
                        \"Failed to initialize the async mode '".
                        \g:SingleCompile_asyncrunmode."'.\n".l:async_init_res)
        elseif l:async_init_res == 3
            call s:ShowMessage("The specified async mode '".
                        \g:SingleCompile_asyncrunmode."' doesn't exist.")
        elseif l:async_init_res != 0
            call s:ShowMessage(
                        \"Failed to initialize the async mode'".
                        \g:SingleCompile_asyncrunmode."'.")
        endif
    endif

    " terminate the background process before existing vim
    if has('autocmd')
        autocmd VimLeave * call SingleCompileAsync#Terminate()
    endif

    " templates {{{2
    if has('win32')
        let l:common_run_command = '$(FILE_TITLE)$.exe'
        let l:common_out_file = '$(FILE_TITLE)$.exe'
    else
        let l:common_run_command = './$(FILE_TITLE)$'
        let l:common_out_file = '$(FILE_TITLE)$'
    endif

    " ada
    call SingleCompile#SetCompilerTemplate('ada', 'gnat', 'GNAT', 'gnat',
                \'make', l:common_run_command)
    call SingleCompile#SetOutfile('ada', 'gnat', l:common_out_file)

    " bash
    call SingleCompile#SetCompilerTemplate('bash', 'bash',
                \'Bourne-Again Shell', 'bash', '', '')

    " c
    call SingleCompile#SetCompilerTemplate('c', 'open-watcom', 
                \'Open Watcom C/C++32 Compiler', 'wcl386', '', 
                \l:common_run_command, function('s:DetectWatcom'))
    call SingleCompile#SetCompilerTemplateByDict('c', 'open-watcom', {
                \ 'pre-do'  : function('s:PredoWatcom'),
                \ 'post-do' : function('s:PostdoWatcom'),
                \ 'out-file': l:common_out_file
                \})
    if has('win32')
        call SingleCompile#SetCompilerTemplate('c', 'msvc', 
                    \'Microsoft Visual C++', 'cl', '-o $(FILE_TITLE)$', 
                    \l:common_run_command)
        call SingleCompile#SetOutfile('c', 'msvc', l:common_out_file)
        call SingleCompile#SetCompilerTemplate('c', 'bcc', 
                    \'Borland C++ Builder', 'bcc32', 
                    \'-o $(FILE_TITLE)$', l:common_run_command)
        call SingleCompile#SetOutfile('c', 'bcc', l:common_out_file)
    endif
    call SingleCompile#SetCompilerTemplate('c', 'gcc', 'GNU C Compiler',
                \'gcc', '-g -o $(FILE_TITLE)$', l:common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('c', 'gcc', {
                \ 'pre-do'  : function('s:PredoGcc'),
                \ 'out-file': l:common_out_file
                \})
    call SingleCompile#SetCompilerTemplate('c', 'icc', 
                \'Intel C++ Compiler', 'icc', '-o $(FILE_TITLE)$',
                \l:common_run_command)
    call SingleCompile#SetOutfile('c', 'icc', l:common_out_file)
    if has('win32')
        call SingleCompile#SetCompilerTemplate('c', 'lcc', 
                    \'Little C Compiler', 'lc', 
                    \'$(FILE_TITLE)$ -o "$(FILE_TITLE)$.exe"', 
                    \l:common_run_command)
    else
        call SingleCompile#SetCompilerTemplate('c', 'lcc',
                    \'Little C Compiler', 'lc', 
                    \'$(FILE_TITLE)$ -o $(FILE_TITLE)$', 
                    \l:common_run_command)
    endif
    call SingleCompile#SetOutfile('c', 'lcc', l:common_out_file)
    call SingleCompile#SetCompilerTemplate('c', 'pcc', 
                \'Portable C Compiler', 'pcc', '-o $(FILE_TITLE)$', 
                \l:common_run_command)
    call SingleCompile#SetOutfile('c', 'pcc', l:common_out_file)
    call SingleCompile#SetCompilerTemplate('c', 'tcc', 'Tiny C Compiler',
                \'tcc', '-o $(FILE_TITLE)$', l:common_run_command)
    call SingleCompile#SetOutfile('c', 'tcc', l:common_out_file)
    call SingleCompile#SetCompilerTemplate('c', 'tcc-run', 
                \'Tiny C Compiler with "-run" Flag', 'tcc', '-run', '')
    call SingleCompile#SetCompilerTemplate('c', 'ch', 
                \'SoftIntegration Ch', 'ch', '', '')
    call SingleCompile#SetCompilerTemplate('c', 'clang', 'clang', 'clang',
                \'-o $(FILE_TITLE)$', l:common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('c', 'clang', {
                \ 'pre-do'  : function('s:PredoClang'),
                \ 'out-file': l:common_out_file
                \})
    if has('unix')
        call SingleCompile#SetCompilerTemplate('c', 'cc', 
                    \'UNIX C Compiler', 'cc', '-o $(FILE_TITLE)$', 
                    \l:common_run_command)
        call SingleCompile#SetOutfile('c', 'cc', l:common_out_file)
        call SingleCompile#SetCompilerTemplate('c', 'sol-studio', 
                    \'Sun C Compiler (Sun Solaris Studio)', 'suncc', 
                    \'-o $(FILE_TITLE)$', l:common_run_command)
        call SingleCompile#SetCompilerTemplateByDict('c', 'sol-studio', {
                    \ 'pre-do'  : function('s:PredoSolStudioC'),
                    \ 'out-file': l:common_out_file
                    \})
        call SingleCompile#SetCompilerTemplate('c', 'open64', 
                    \'Open64 C Compiler', 'opencc', '-o $(FILE_TITLE)$',
                    \l:common_run_command)
    endif

    " cpp
    call SingleCompile#SetCompilerTemplate('cpp', 'open-watcom', 
                \'Open Watcom C/C++32 Compiler', 
                \'wcl386', '', l:common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('cpp', 'open-watcom', {
                \ 'pre-do'  : function('s:PredoWatcom'),
                \ 'post-do' : function('s:PostdoWatcom'),
                \ 'out-file': l:common_out_file
                \})
    if has('win32')
        call SingleCompile#SetCompilerTemplate('cpp', 'msvc', 
                    \'Microsoft Visual C++', 'cl', '-o $(FILE_TITLE)$', 
                    \l:common_run_command)
        call SingleCompile#SetOutfile('cpp', 'msvc', l:common_out_file)
        call SingleCompile#SetCompilerTemplate('cpp', 'bcc', 
                    \'Borland C++ Builder','bcc32', '-o $(FILE_TITLE)$', 
                    \l:common_run_command)
        call SingleCompile#SetOutfile('cpp', 'bcc', l:common_out_file)
    endif
    call SingleCompile#SetCompilerTemplate('cpp', 'g++', 
                \'GNU C++ Compiler', 'g++', '-g -o $(FILE_TITLE)$', 
                \l:common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('cpp', 'g++', {
                \ 'pre-do'  : function('s:PredoGcc'),
                \ 'out-file': l:common_out_file,
                \ 'vim-compiler': 'gcc'
                \})
    call SingleCompile#SetCompilerTemplate('cpp', 'icc', 
                \'Intel C++ Compiler', 'icc', '-o $(FILE_TITLE)$', 
                \l:common_run_command)
    call SingleCompile#SetOutfile('cpp', 'icc', l:common_out_file)
    call SingleCompile#SetCompilerTemplate('cpp', 'ch', 
                \'SoftIntegration Ch', 'ch', '', '')
    call SingleCompile#SetCompilerTemplate('cpp', 'clang++', 'clang', 
                \'clang++', '-o $(FILE_TITLE)$', l:common_run_command)
    call SingleCompile#SetCompilerTemplateByDict('cpp', 'clang++', {
                \ 'pre-do'  : function('s:PredoClang'),
                \ 'out-file': l:common_out_file,
                \ 'vim-compiler': 'clang'
                \})
    if has('unix')
        call SingleCompile#SetCompilerTemplate('cpp', 'sol-studio', 
                    \'Sun C++ Compiler (Sun Solaris Studio)', 'sunCC', 
                    \'-o $(FILE_TITLE)$', l:common_run_command)
        call SingleCompile#SetCompilerTemplateByDict('cpp', 'sol-studio',{
                    \ 'pre-do'  : function('s:PredoSolStudioC'),
                    \ 'out-file': l:common_out_file
                    \})
        call SingleCompile#SetCompilerTemplate('cpp', 'open64', 
                    \'Open64 C++ Compiler', 'openCC', 
                    \'-o $(FILE_TITLE)$', l:common_run_command)
        call SingleCompile#SetOutfile('cpp', 'open64', l:common_out_file)
    endif

    " c#
    if has('win32')
        call SingleCompile#SetCompilerTemplate('cs', 'msvcs',
                    \'Microsoft Visual C#', 'csc', '',
                    \l:common_run_command)
        call SingleCompile#SetOutfile('cs', 'msvcs',
                    \l:common_out_file)
        call SingleCompile#SetVimCompiler('cs', 'msvcs', 'cs')
    endif
    call SingleCompile#SetCompilerTemplate('cs', 'mono',
                \'Mono C# compiler', 'mcs', '',
                \'mono $(FILE_TITLE)$'.'.exe')
    call SingleCompile#SetOutfile('cs', 'mono',
                \'$(FILE_TITLE)$'.'.exe')
    call SingleCompile#SetVimCompiler('cs', 'mono', 'mcs')

    " cmake
    call SingleCompile#SetCompilerTemplate('cmake', 'cmake', 'cmake',
                \'cmake', '', '')

    " csh
    call SingleCompile#SetCompilerTemplate('csh', 'csh',
                \'C Shell', 'csh', '', '')
    call SingleCompile#SetCompilerTemplate('csh', 'tcsh',
                \'TENEX C shell', 'tcsh', '', '')

    " d
    call SingleCompile#SetCompilerTemplate('d', 'dmd', 'DMD Compiler',
                \'dmd', '', l:common_run_command)

    " dosbatch
    if has('win32')
        call SingleCompile#SetCompilerTemplate('dosbatch', 'dosbatch', 
                    \'DOS Batch', '', '', '',
                    \function('s:DetectDosbatch'))
    endif

    " erlang
    call SingleCompile#SetCompilerTemplate('erlang', 'escript',
                \'Erlang Scripting Support', 'escript', '', '')

    " fortran
    call SingleCompile#SetCompilerTemplate('fortran', 'gfortran', 
                \'GNU Fortran Compiler', 'gfortran', 
                \'-o $(FILE_TITLE)$', l:common_run_command)
    call SingleCompile#SetOutfile('fortran', 'gfortran',
                \l:common_out_file)
    call SingleCompile#SetCompilerTemplate('fortran', 'g95',
                \'G95', 'g95', '-o $(FILE_TITLE)$'.s:ExecutableSuffix,
                \l:common_run_command)
    call SingleCompile#SetOutfile('fortran', 'g95', l:common_out_file)
    if has('unix')
        call SingleCompile#SetCompilerTemplate('fortran', 
                    \'sol-studio-f77', 
                    \'Sun Fortran 77 Compiler (Sun Solaris Studio)', 
                    \'sunf77', '-o $(FILE_TITLE)$', 
                    \l:common_run_command)
        call SingleCompile#SetOutfile('fortran', 'sol-studio-f77', 
                    \l:common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran', 
                    \'sol-studio-f90', 
                    \'Sun Fortran 90 Compiler (Sun Solaris Studio)', 
                    \'sunf90', '-o $(FILE_TITLE)$', 
                    \l:common_run_command)
        call SingleCompile#SetOutfile('fortran', 'sol-studio-f90', 
                    \l:common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran', 
                    \'sol-studio-f95', 
                    \'Sun Fortran 95 Compiler (Sun Solaris Studio)', 
                    \'sunf95', '-o $(FILE_TITLE)$', 
                    \l:common_run_command)
        call SingleCompile#SetOutfile('fortran', 'sol-studio-f95', 
                    \l:common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran', 'open64-f90',
                    \'Open64 Fortran 90 Compiler', 'openf90', 
                    \'-o $(FILE_TITLE)$', l:common_run_command)
        call SingleCompile#SetOutfile('fortran', 'open64-f90', 
                    \l:common_out_file)
        call SingleCompile#SetCompilerTemplate('fortran', 'open64-f95',
                    \'Open64 Fortran 95 Compiler', 'openf95', 
                    \'-o $(FILE_TITLE)$', l:common_run_command)
        call SingleCompile#SetOutfile('fortran', 'open64-f95', 
                    \l:common_out_file)
    endif
    if has('win32')
        call SingleCompile#SetCompilerTemplate('fortran', 'ftn95',
                    \'Silverfrost FTN95', 'ftn95', '$(FILE_NAME)$ /LINK',
                    \l:common_run_command)
        call SingleCompile#SetOutfile('fortran', 'ftn95', 
                    \l:common_out_file)
    endif
    call SingleCompile#SetCompilerTemplate('fortran', 'g77', 
                \'GNU Fortran 77 Compiler', 'g77', '-o $(FILE_TITLE)$',
                \l:common_run_command)
    call SingleCompile#SetOutfile('fortran', 'g77', l:common_out_file)
    call SingleCompile#SetVimCompiler('fortran', 'g77', 'fortran_g77')
    call SingleCompile#SetCompilerTemplate('fortran', 'ifort', 
                \'Intel Fortran Compiler', 'ifort', '-o $(FILE_TITLE)$',
                \l:common_run_command)
    call SingleCompile#SetOutfile('fortran', 'ifort', l:common_out_file)
    call SingleCompile#SetCompilerTemplate('fortran', 'open-watcom', 
                \'Open Watcom Fortran 77/32 Compiler', 'wfl386', '',
                \l:common_run_command, function('s:DetectWatcom'))
    call SingleCompile#SetCompilerTemplateByDict('fortran', 'open-watcom', 
                \{
                \ 'pre-do'  : function('s:PredoWatcom'),
                \ 'post-do' : function('s:PostdoWatcom'),
                \ 'out-file': l:common_out_file
                \})

    " haskell
    call SingleCompile#SetCompilerTemplate('haskell', 'ghc', 
                \'Glasgow Haskell Compiler', 'ghc', '-o $(FILE_TITLE)$',
                \l:common_run_command)
    call SingleCompile#SetOutfile('haskell', 'ghc', l:common_out_file)
    call SingleCompile#SetCompilerTemplate('haskell', 'runhaskell', 
                \'runhaskell', 'runhaskell', '', '')

    " html
    call SingleCompile#SetCompilerTemplate('html', 'firefox', 
                \'Mozilla Firefox', 'firefox', '', '')
    call SingleCompile#SetCompilerTemplate('html', 'chrome', 
                \'Google Chrome', 'google-chrome', '', '')
    call SingleCompile#SetCompilerTemplate('html', 'opera', 'Opera', 
                \'opera', '', '')
    call SingleCompile#SetCompilerTemplate('html', 'konqueror',
                \'Konqueror', 'konqueror', '', '')
    call SingleCompile#SetCompilerTemplate('html', 'arora',
                \'Arora', 'arora', '', '')
    call SingleCompile#SetCompilerTemplate('html', 'epiphany',
                \'Epiphany', 'epiphany', '', '')
    if has('win32')
        call SingleCompile#SetCompilerTemplate('html', 'ie', 
                    \'Microsoft Internet Explorer', 'iexplore', '', '',
                    \function('s:DetectIe'))
    else
        call SingleCompile#SetCompilerTemplate('html', 'ie', 
                    \'Microsoft Internet Explorer', 'iexplore', '', '')
    endif

    " idlang (Interactive Data Language)
    call SingleCompile#SetCompilerTemplate('idlang', 'idl',
                \'ITT Visual Information Solutions '.
                \'Interactive Data Language', 'idl',
                \"-quiet -e '.run $(FILE_NAME)$'", '')
    call SingleCompile#SetCompilerTemplate('idlang', 'gdl',
                \'GNU Data Language incremental compiler',
                \'gdl', "-quiet -e '.run $(FILE_NAME)$'", '')

    " java
    call SingleCompile#SetCompilerTemplate('java', 'sunjdk', 
                \ 'Sun Java Development Kit', 'javac', '', 
                \'java $(FILE_TITLE)$')
    call SingleCompile#SetOutfile('java', 'sunjdk', 
                \'$(FILE_TITLE)$'.'.class')
    call SingleCompile#SetVimCompiler('java', 'sunjdk', 'javac')
    call SingleCompile#SetCompilerTemplate('java', 'gcj', 
                \'GNU Java Compiler', 'gcj', '', 'java $(FILE_TITLE)$')
    call SingleCompile#SetOutfile('java', 'gcj', '$(FILE_TITLE)$'.'.class')

    " javascript
    call SingleCompile#SetCompilerTemplate('javascript', 'js',
                \'SpiderMonkey, a JavaScript engine written in C',
                \'js', '', '')
    call SingleCompile#SetCompilerTemplate('javascript', 'rhino',
                \'Rhino, a JavaScript engine written in Java',
                \'rhino', '', '')

    " ksh
    call SingleCompile#SetCompilerTemplate('ksh', 'ksh',
                \'Korn Shell', 'ksh', '', '')

    " latex
    if has('unix')
        call SingleCompile#SetCompilerTemplate('tex', 'pdflatex', 'pdfLaTeX',
                    \'pdflatex', '-interaction=nonstopmode',
                    \'xdg-open "$(FILE_TITLE)$.pdf"')
        call SingleCompile#SetCompilerTemplate('tex', 'latex', 'LaTeX',
                    \'latex', '-interaction=nonstopmode',
                    \'xdg-open "$(FILE_TITLE)$.dvi"')
    elseif has('win32')
        call SingleCompile#SetCompilerTemplate('tex', 'pdflatex', 'pdfLaTeX',
                    \'pdflatex', '-interaction=nonstopmode',
                    \'open "$(FILE_TITLE)$.pdf"')
        call SingleCompile#SetCompilerTemplate('tex', 'latex', 'LaTeX',
                    \'latex', '-interaction=nonstopmode',
                    \'open "$(FILE_TITLE)$.dvi"')
    endif

    " lisp
    call SingleCompile#SetCompilerTemplate('lisp', 'clisp', 'GNU CLISP',
                \'clisp', '', '')
    call SingleCompile#SetCompilerTemplate('lisp', 'ecl', 
                \'Embeddable Common-Lisp', 'ecl', '-shell', '')
    call SingleCompile#SetCompilerTemplate('lisp', 'gcl', 
                \'GNU Common Lisp', 'gcl', '-batch -load', '')

    " lua
    call SingleCompile#SetCompilerTemplate('lua', 'lua', 
                \'Lua Interpreter', 'lua', '', '')

    " Makefile
    call SingleCompile#SetCompilerTemplate('make', 'gmake', 'GNU Make',
                \'gmake', '-f', '', function('s:DetectGmake'))
    call SingleCompile#SetCompilerTemplate('make', 'mingw32-make',
                \'MinGW32 Make', 'mingw32-make', '-f', '')
    if has('win32')
        call SingleCompile#SetCompilerTemplate('make', 'nmake', 
                    \'Microsoft Program Maintenance Utility', 'nmake',
                    \'-f', '')
    endif

    " Object-C
    call SingleCompile#SetCompilerTemplate('objc', 'gcc',
                \'GNU Object-C Compiler', 'gcc', '-g -o $(FILE_TITLE)$',
                \l:common_run_command)
    call SingleCompile#SetOutfile('objc', 'gcc', l:common_out_file)

    " Pascal
    call SingleCompile#SetCompilerTemplate('pascal', 'fpc', 
                \'Free Pascal Compiler', 'fpc', 
                \'', l:common_run_command)
    call SingleCompile#SetOutfile('pascal', 'fpc',
                \l:common_out_file)
    call SingleCompile#SetCompilerTemplate('pascal', 'gpc', 
                \'GNU Pascal Compiler', 'gpc', 
                \'-o $(FILE_TITLE)$', l:common_run_command)
    call SingleCompile#SetOutfile('pascal', 'gpc',
                \l:common_out_file)


    " perl
    call SingleCompile#SetCompilerTemplate('perl', 'perl', 
                \'Perl Interpreter', 'perl', '', '')

    " php
    call SingleCompile#SetCompilerTemplate('php', 'php',
                \"PHP Command Line Interface 'CLI'", 'php', '-f', '')

    " python
    call SingleCompile#SetCompilerTemplate('python', 'python', 'CPython',
                \'python', '', '')
    call SingleCompile#SetCompilerTemplate('python', 'ironpython',
                \'IronPython', 'ipy', '', '')
    call SingleCompile#SetCompilerTemplate('python', 'jython', 'Jython',
                \'jython', '', '')
    call SingleCompile#SetCompilerTemplate('python', 'pypy', 'PyPy',
                \'pypy', '', '')
    call SingleCompile#SetCompilerTemplate('python', 'python3', 
                \'CPython 3', 'python3', '', '')

    " r
    call SingleCompile#SetCompilerTemplate('r', 'R', 'R', 'R',
                \'CMD BATCH', '')

    " ruby
    call SingleCompile#SetCompilerTemplate('ruby', 'ruby', 
                \'Ruby Interpreter', 'ruby', '', '')

    " sh
    call SingleCompile#SetCompilerTemplate('sh', 'sh', 
                \'Bourne Shell', 'sh', '', '')
    call SingleCompile#SetCompilerTemplate('sh', 'bash', 
                \'Bourne-Again Shell', 'bash', '', '')
    call SingleCompile#SetCompilerTemplate('sh', 'ksh', 
                \'Korn Shell', 'ksh', '', '')
    call SingleCompile#SetCompilerTemplate('sh', 'zsh', 
                \'Z Shell', 'zsh', '', '')
    call SingleCompile#SetCompilerTemplate('sh', 'ash', 
                \'Almquist Shell', 'ash', '', '')
    call SingleCompile#SetCompilerTemplate('sh', 'dash', 
                \'Debian Almquist Shell', 'dash', '', '')

    " tcl
    call SingleCompile#SetCompilerTemplate('tcl', 'tclsh', 
                \'Simple shell containing Tcl interpreter', 'tclsh', 
                \'', '')
    call SingleCompile#SetVimCompiler('tcl', 'tclsh', 'tcl')

    " tcsh
    call SingleCompile#SetCompilerTemplate('tcsh', 'tcsh',
                \'TENEX C Shell', 'tcsh', '', '')

    " vbs
    call SingleCompile#SetCompilerTemplate('vb', 'vbs', 
                \'VB Script Interpreter', 'cscript', '', '')

    " xhtml
    call SingleCompile#SetCompilerTemplate('xhtml', 'firefox', 
                \'Mozilla Firefox', 'firefox', '', '')
    call SingleCompile#SetCompilerTemplate('xhtml', 'chrome', 
                \'Google Chrome', 'google-chrome', '', '')
    call SingleCompile#SetCompilerTemplate('xhtml', 'opera', 
                \'Opera', 'opera', '', '')
    call SingleCompile#SetCompilerTemplate('xhtml', 'konqueror',
                \'Konqueror', 'konqueror', '', '')
    call SingleCompile#SetCompilerTemplate('xhtml', 'arora',
                \'Arora', 'arora', '', '')
    call SingleCompile#SetCompilerTemplate('xhtml', 'epiphany',
                \'Epiphany', 'epiphany', '', '')
    if has('win32')
        call SingleCompile#SetCompilerTemplate('xhtml', 'ie', 
                    \'Microsoft Internet Explorer', 'iexplore', '', '',
                    \function('s:DetectIe'))
    else
        call SingleCompile#SetCompilerTemplate('xhtml', 'ie', 
                    \'Microsoft Internet Explorer', 'iexplore', '', '')
    endif

    " zsh
    call SingleCompile#SetCompilerTemplate('zsh', 'zsh', 
                \'Z Shell', 'zsh', '', '')
    " 2}}}
endfunction

function! s:SetVimCompiler(lang_name, compiler) " {{{1
    " call the :compiler command

    let l:dict_compiler = s:CompilerTemplate[a:lang_name][a:compiler]
    if has_key(l:dict_compiler, 'vim-compiler')
        silent! exec 'compiler '.l:dict_compiler['vim-compiler']
    else
        silent! exec 'compiler '.a:compiler
    endif
endfunction

function! s:SetGlobalVimCompiler(lang_name, compiler) " {{{1
    "call the :compiler! command

    let l:dict_compiler = s:CompilerTemplate[a:lang_name][a:compiler]
    if has_key(l:dict_compiler, 'vim-compiler')
        silent! exec 'compiler! '.l:dict_compiler['vim-compiler']
    else
        silent! exec 'compiler! '.a:compiler
    endif
endfunction

" SingleCompile#SetCompilerTemplate {{{1
function! SingleCompile#SetCompilerTemplate(lang_name, compiler,
            \compiler_name, detect_func_arg, flags, run_command, ...) 
    " set compiler's template, including compiler, compiler's name, the
    " detecting function argument, compilation flags, run command and
    " a compiler detecting function which is optional.

    call s:Initialize()

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'name',
                \a:compiler_name)
    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler,
                \'detect_func_arg', a:detect_func_arg)
    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'flags',
                \a:flags)
    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'run',
                \a:run_command)
    if a:0 == 0
        call SingleCompile#SetDetectFunc(a:lang_name, a:compiler,
                    \function("s:DetectCompilerGenerally"))
    else
        call SingleCompile#SetDetectFunc(a:lang_name, a:compiler, a:1)
    endif
endfunction

" function! SingleCompile#SetCompilerTemplateByDict {{{1
function! SingleCompile#SetCompilerTemplateByDict(
            \lang_name, compiler, template_dict) 
    " set templates by using a dict(template_dict), thus calling the template
    " settings functions below one by one is not needed.

    let l:key_list = ['name', 'detect_func_arg', 'flags', 'run',
                \'detect_func', 'pre-do', 'post-do', 'out-file',
                \'vim-compiler']

    for key in l:key_list
        if has_key(a:template_dict, key)
            call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, key,
                        \get(a:template_dict, key))
        endif
    endfor
endfunction

" extra template settings functions {{{1
function! SingleCompile#SetDetectFunc(lang_name, compiler, detect_func) " {{{2
    " set the detect_func function 

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'detect_func',
                \a:detect_func)
endfunction

function! SingleCompile#SetPredo(lang_name, compiler, predo_func) " {{{2
    " set the pre-do function 

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'pre-do',
                \a:predo_func)
endfunction

function! SingleCompile#SetPostdo(lang_name, compiler, postdo_func) " {{{2
    " set the post-do function 

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 
                \'post-do', a:postdo_func)
endfunction

function! SingleCompile#SetOutfile(lang_name, compiler, outfile) " {{{2
    " set out-file

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 
                \'out-file', a:outfile)
endfunction

fun! SingleCompile#SetVimCompiler(lang_name, compiler, vim_compiler) " {{{2
    " set vim-compiler

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler,
                \'vim-compiler', a:vim_compiler)
endfunction

function! s:GetCompilerSingleTemplate(lang_name, compiler_name, key) " {{{1
    return s:CompilerTemplate[a:lang_name][a:compiler_name][a:key]
endfunction

" SetCompilerSingleTemplate {{{1
fun! s:SetCompilerSingleTemplate(lang_name, compiler, key, value, ...)
    " set the template. if the '...' is nonzero, this function will not
    " override the corresponding template if there is an existing template 

    " Set the default template first so that we could let this override the 
    " default compile template.
    call s:Initialize()

    if a:0 > 1
        call s:ShowMessage(
                    \'Too many argument for'.
                    \' SingleCompile#SetCompilerSingleTemplate function!')
        return
    endif

    " if the key a:lang_name does not exist, create it
    if !has_key(s:CompilerTemplate,a:lang_name)
        let s:CompilerTemplate[a:lang_name] = {}
    elseif type(s:CompilerTemplate[a:lang_name]) != type({})
        unlet! s:CompilerTemplate[a:lang_name]
        let s:CompilerTemplate[a:lang_name] = {}
    endif

    " if a:compiler does not exist, create it
    if !has_key(s:CompilerTemplate[a:lang_name],a:compiler)
        let s:CompilerTemplate[a:lang_name][a:compiler] = {}
    elseif type(s:CompilerTemplate[a:lang_name][a:compiler]) != type({})
        unlet! s:CompilerTemplate[a:lang_name][a:compiler]
        let s:CompilerTemplate[a:lang_name][a:compiler] = {}
    endif

    " if a:key does not exist, create it
    " if the ... from the argument is 0 or the additional argument does
    " not exist, also override the original one
    if !has_key(s:CompilerTemplate[a:lang_name][a:compiler], a:key) || 
                \a:0 == 0 || a:1 == 0 
        let s:CompilerTemplate[a:lang_name][a:compiler][a:key] = a:value
    endif
endfunction

function! SingleCompile#SetTemplate(langname, stype, string,...) " {{{1
    " set the template. if the '...' is nonzero, this function will not
    " override the corresponding template if there is an existing template
    
    if a:0 > 1
        call s:ShowMessage('Too many argument for '.
                    \'SingleCompile#SetTemplate function')
        return
    endif

    " if g:SingleCompile_templates does not exist or it is not a dic, then
    " make g:SingleCompile_templates a dic
    if !exists('g:SingleCompile_templates') || type(g:SingleCompile_templates)
                \!= type({})
        unlet! g:SingleCompile_templates
        let g:SingleCompile_templates={}
    endif

    " if the key a:langname does not exist, create it
    if !has_key(g:SingleCompile_templates,a:langname)
        let g:SingleCompile_templates[a:langname]={}
    elseif type(g:SingleCompile_templates[a:langname]) != type({})
        unlet! g:SingleCompile_templates[a:langname]
        let g:SingleCompile_templates[a:langname]={}
    endif

    " if a:stype does not exist, create it
    if !has_key(g:SingleCompile_templates[a:langname],a:stype)
        let g:SingleCompile_templates[a:langname][a:stype] = a:string
    elseif type(g:SingleCompile_templates[a:langname][a:stype]) != type('')
        unlet! g:SingleCompile_templates[a:langname][a:stype]
        let g:SingleCompile_templates[a:langname][a:stype] = a:string
    elseif a:0 == 0 || a:1 == 0 
        " if the ... from the argument is 0 or the additional argument does
        " not exist
        let g:SingleCompile_templates[a:langname][a:stype] = a:string
    endif
endfunction


function! s:ShowMessage(message) "{{{1

    if g:SingleCompile_usedialog == 0 || !((has('gui_running') &&
                \has('dialog_gui')) || has('dialog_con'))
        echohl Error | echo 'SingleCompile: '.a:message | echohl None
    else
        call confirm('SingleCompile: '.a:message)
    endif

endfunction

function! s:IsLanguageInterpreting(filetype_name) "{{{1 
    "tell if a language is an interpreting language, reutrn 1 if yes, 0 if no

    if has_key(g:SingleCompile_templates, a:filetype_name)
        return (!has_key(g:SingleCompile_templates[a:filetype_name],'run') ||
                    \substitute(
                    \g:SingleCompile_templates[a:filetype_name]['run'], ' ',
                    \'',"g") 
                    \== '')
    else
        let l:chosen_compiler =
                    \s:CompilerTemplate[a:filetype_name]['chosen_compiler']
        return (!has_key(
                    \s:CompilerTemplate[a:filetype_name][l:chosen_compiler], 
                    \'run')
                    \ || substitute(
                    \s:CompilerTemplate[a:filetype_name][l:chosen_compiler]
                    \['run'], 
                    \' ', '', "g") == '')
    endif
endfunction

function! s:ShouldQuickfixBeUsed() " tell whether quickfix sould be used{{{1
    if g:SingleCompile_usequickfix == 0
                \ || !has('quickfix') 
                \ || ( s:IsLanguageInterpreting(&filetype) && !has('unix') )
        return 0
    else
        return 1
    endif
endfunction

function! SingleCompile#Compile(...) " compile synchronously {{{1
    return s:CompileInternal(a:000, 0)
endfunction

function! SingleCompile#CompileAsync(...) " compile asynchronously {{{1
    return s:CompileInternal(a:000, 1)
endfunction

function! s:CompileInternal(arg_list, async) " compile only {{{1
    call s:Initialize()
    let l:toret = 0

    " whether we should run asynchronously if we are working with an
    " interpreting language
    let l:async = a:async && !empty(SingleCompileAsync#GetMode())

    " save current file type. Don't use &filetype directly because after
    " 'make' and quickfix is working and the error is in another file,
    " sometimes the value of &filetype may be incorrect.
    let l:cur_filetype = &filetype 

    " if current filetype is an empty string, show an error message and
    " return.
    if l:cur_filetype == ''
        call s:ShowMessage(
                    \"Current buffer's filetype is not specified. ".
                    \"Use \" :help 'filetype' \" command to see more details".
                    \" if you don't know what filetype is.")
        return -1
    endif

    " If the following condition is met, then use the user specified command.
    " The user-specified mode is for backward compatibility, we have to switch
    " to the old mode(which is user-specified mode) if user has modified
    " g:SingleCompile_templates for current file type.
    if has_key(g:SingleCompile_templates, l:cur_filetype) && 
                \has_key(g:SingleCompile_templates[l:cur_filetype], 'command')
        let l:user_specified = 1
    elseif has_key(s:CompilerTemplate, l:cur_filetype) && 
                \type(s:CompilerTemplate[l:cur_filetype]) == type({})
        let l:user_specified = 0
    else
        call s:ShowMessage('Language template for "'.
                    \l:cur_filetype.'" is not defined on your system.')
        return -1
    endif

    " if current buffer has no name (for example the buffer has never been
    " saved), don't compile
    if bufname('%') == ''
        call s:ShowMessage(
                    \'Current buffer does not have a file name. '.
                    \'Please save current buffer first. '.
                    \'Compilation canceled.')
        return -1
    endif


    " if autowrite is set and the buffer has been modified, then save
    if g:SingleCompile_autowrite != 0 && &modified != 0
        write
    endif

    " if user specified is zero, then detect compilers
    if l:user_specified == 0
        if !has_key(s:CompilerTemplate[l:cur_filetype], 'chosen_compiler')
            let l:detected_compilers = s:DetectCompiler(l:cur_filetype)
            " if l:detected_compilers is empty, then no compiler is detected
            if empty(l:detected_compilers)
                call s:ShowMessage(
                            \'No compiler is detected on your system!')
                return -1
            endif

            let s:CompilerTemplate[l:cur_filetype]['chosen_compiler'] = 
                        \get(l:detected_compilers, 0)
        endif
        let l:chosen_compiler = 
                    \s:CompilerTemplate[l:cur_filetype]['chosen_compiler']
        let l:compile_cmd = s:GetCompilerSingleTemplate(
                    \l:cur_filetype, l:chosen_compiler, 'command')
    elseif l:user_specified == 1
        let l:compile_cmd = 
                    \g:SingleCompile_templates[l:cur_filetype]['command']
    endif

    " save current working directory
    let l:cwd = getcwd()
    " switch current work directory to the file's directory
    silent lcd %:p:h

    " If it's not user_specified and current language is not interpreting
    " language, check the last modification time of the file, whose name is
    " the value of the 'out-file' key. If the last modification time of that
    " file is earlier than the last modification time of current buffer's
    " file, don't compile.
    if !g:SingleCompile_alwayscompile && l:user_specified == 0 
                \&& !s:IsLanguageInterpreting(l:cur_filetype)
                \&& has_key(
                \s:CompilerTemplate[l:cur_filetype][l:chosen_compiler], 
                \'out-file')
                \&& getftime(s:Expand(
                \s:CompilerTemplate[l:cur_filetype][l:chosen_compiler]
                \['out-file'], 0))
                \> getftime(expand('%:p'))
        " switch back to the original directory
        exec 'lcd '.escape(l:cwd, s:CharsEscape)
        echo 'SingleCompile: '.
                    \'No need to compile. '.
                    \'No modification is detected.'
        return 0
    endif

    if len(a:arg_list) == 1 
        " if there is only one argument, it means use this argument as the
        " compilation flag
 
        let l:compile_flags = a:arg_list[0]
    elseif len(a:arg_list) == 2 && l:user_specified == 1 && 
                \has_key(g:SingleCompile_templates[l:cur_filetype],'flags') 
        " if there are two arguments, it means append the provided argument to
        " the flag defined in the template

        let l:compile_flags = 
                    \g:SingleCompile_templates[l:cur_filetype]['flags'].
                    \' '.a:arg_list[1]
    elseif len(a:arg_list) == 0 && l:user_specified == 1 && 
                \has_key(g:SingleCompile_templates[l:cur_filetype],'flags')
        let l:compile_flags = 
                    \g:SingleCompile_templates[l:cur_filetype]['flags']
    elseif len(a:arg_list) == 2 && l:user_specified == 0 && has_key(
                \s:CompilerTemplate[l:cur_filetype][ 
                \s:CompilerTemplate[l:cur_filetype]['chosen_compiler']], 
                \'flags')
        " if there are two arguments, it means append the provided argument to
        " the flag defined in the template

        let l:compile_flags = s:GetCompilerSingleTemplate(l:cur_filetype, 
                    \s:CompilerTemplate[l:cur_filetype]['chosen_compiler'], 
                    \'flags').' '.a:arg_list[1]
    elseif len(a:arg_list) == 0 && l:user_specified == 0 && has_key(
                \s:CompilerTemplate[l:cur_filetype][ 
                \s:CompilerTemplate[l:cur_filetype]['chosen_compiler']], 
                \'flags')
        let l:compile_flags = s:GetCompilerSingleTemplate(l:cur_filetype,
                    \s:CompilerTemplate[l:cur_filetype]['chosen_compiler'],
                    \'flags')
    else  
        " if a:0 is zero and 'flags' is not defined, assign '' to let
        " l:compile_flags

        let l:compile_flags = ''
    endif

    
    if match(l:compile_flags, '\$(FILE_PATH)\$') == -1 && 
                \match(l:compile_flags, '\$(FILE_NAME)\$') == -1
        let l:compile_flags = l:compile_flags.' $(FILE_PATH)$'
    endif
    let l:compile_args = s:Expand(l:compile_flags)

    " call the pre-do function if set
    if l:user_specified == 0 && 
                \has_key(
                \s:CompilerTemplate[l:cur_filetype][l:chosen_compiler],
                \'pre-do')
        let l:command_dic = 
                    \s:CompilerTemplate[l:cur_filetype][l:chosen_compiler][
                    \'pre-do'](
                    \{ 'command': l:compile_cmd, 
                    \'args': l:compile_args})
        let l:compile_cmd = l:command_dic['command']
        let l:compile_args = l:command_dic['args']
    endif



    if s:ShouldQuickfixBeUsed() == 0
        " if quickfix is not enabled for this plugin or the language is an
        " interpreting language not in unix, then don't use quickfix

        if l:async && s:IsLanguageInterpreting(l:cur_filetype)

            call s:RunAsyncWithMessage(l:compile_cmd.' '.l:compile_args)
        else
            exec '!'.l:compile_cmd.' '.l:compile_args

            " check whether compiling is successful, if not, show the return value
            " with error message highlighting and set the return value to 1
            if v:shell_error != 0
                echo ' '
                echohl ErrorMsg | echo 'Error! Return value is '.v:shell_error 
                            \| echohl None
                let l:toret = 1
            endif
        endif

    elseif has('unix') && s:IsLanguageInterpreting(l:cur_filetype) 
        " use quickfix for interpreting language in unix

        if l:async
            " run the interpreter asynchronously

            call s:RunAsyncWithMessage(l:compile_cmd.' '.l:compile_args)
        else
            " save old values of makeprg and errorformat which :compiler!
            " command may change
            let l:old_makeprg = &g:makeprg
            let l:old_errorformat = &g:errorformat

            " if we are not in user-specified mode, then call :compiler
            " command to set vim compiler
            if l:user_specified == 0
                call s:SetGlobalVimCompiler(l:cur_filetype, l:chosen_compiler)
            endif

            let s:run_result_tempfile = tempname()
            exec '!'.l:compile_cmd.' '.l:compile_args.' '.s:GetShellPipe(1).
                        \' '.s:run_result_tempfile

            cgetexpr readfile(s:run_result_tempfile)

            " recover the old makeprg and errorformat value
            let &g:makeprg = l:old_makeprg
            let &g:errorformat = l:old_errorformat
        endif

    else " use quickfix for compiling language

        " change the makeprg and shellpipe temporarily 
        let l:old_makeprg = &l:makeprg
        let l:old_shellpipe = &l:shellpipe
        let l:old_errorformat = &l:errorformat

        " if we are not in user-specified mode, then call :compiler command to 
        " set vim compiler
        if l:user_specified == 0
            call s:SetVimCompiler(l:cur_filetype, l:chosen_compiler)
        endif

        let &l:makeprg = l:compile_cmd
        let &l:shellpipe = s:GetShellPipe(0)
        exec 'make'.' '.l:compile_args

        " check whether compiling is successful, if not, show the return value
        " with error message highlighting and set the return value to 1
        if v:shell_error != 0
            echo ' '
            echohl ErrorMsg | echo 'Return value is '.v:shell_error 
                        \| echohl None
            let l:toret = 1
        endif

        " set back makeprg and shellpipe
        let &l:makeprg = l:old_makeprg
        let &l:shellpipe = l:old_shellpipe
        let &l:errorformat = l:old_errorformat
    endif

    " if it's interpreting language, then return 2 (means do not call run if
    " user uses SCCompileRun command
    if s:IsLanguageInterpreting(l:cur_filetype)
        let l:toret = 2
    endif

    " call the post-do function if set
    if l:user_specified == 0 && 
                \has_key(s:CompilerTemplate[l:cur_filetype][
                \l:chosen_compiler], 
                \'post-do')
        let l:TmpFunc = s:CompilerTemplate[l:cur_filetype][l:chosen_compiler][
                    \'post-do']
        call l:TmpFunc({'command': l:compile_cmd, 'args': l:compile_args})
    endif


    " switch back to the original directory
    exec 'lcd '.escape(l:cwd, s:CharsEscape)

    " show the quickfix window if error occurs, quickfix is used and 
    " g:SingleCompile_showquickfixiferror is set to nonzero
    if l:toret == 1 && g:SingleCompile_showquickfixiferror &&
                \s:ShouldQuickfixBeUsed()
        cope
    endif

    " if tee is available, and we are running an interpreting language source
    " file, and we want to show the result window right after the run, and we
    " are not running it asynchronously, then we call SingleCompile#ViewResult
    if executable('tee') && l:toret == 2 && !l:async
                \&& g:SingleCompile_showresultafterrun == 1
        call SingleCompile#ViewResult()
    endif

    return l:toret
endfunction


function! s:DetectCompiler(lang_name) " {{{1
    " to detect compilers for one language. Return available compilers

    let l:toret = []

    " call the compiler detection function to get the compilation command
    for some_compiler in keys(s:CompilerTemplate[a:lang_name])
        if some_compiler == 'chosen_compiler'
            continue
        endif

        let l:DetectFunc = s:CompilerTemplate[a:lang_name][some_compiler][
                    \'detect_func']

        call s:SetCompilerSingleTemplate(
                    \a:lang_name, 
                    \some_compiler,
                    \'command', 
                    \l:DetectFunc(
                    \s:CompilerTemplate[a:lang_name][some_compiler][
                    \'detect_func_arg']))

        " if the type of s:CompilerTemplate[&filetype]['command'] returned
        " by the detection function is not a string, then we may think
        " that this compiler cannot be detected
        if type(s:CompilerTemplate[a:lang_name][some_compiler]['command']) == 
                    \type('')
            call add(l:toret, some_compiler)
        endif
    endfor

    return l:toret
endfunction

function! s:Run(async) " {{{1
    " if async is non-zero, then run asynchronously

    let l:ret_val = 0

    call s:Initialize()

    " whether we should use async mode
    let l:async = a:async && !empty(SingleCompileAsync#GetMode())

    if has_key(g:SingleCompile_templates,&filetype) && 
                \has_key(g:SingleCompile_templates[&filetype],'run')
        let l:user_specified = 1
    elseif has_key(s:CompilerTemplate[&filetype][ 
                \s:CompilerTemplate[&filetype]['chosen_compiler']],
                \'run')
        let l:user_specified = 0
    else
        call s:ShowMessage('Fail to run!')
        return 1
    endif

    " save current working directory
    let l:cwd = getcwd()
    silent lcd %:p:h

    if l:user_specified == 1
        let l:run_cmd =
                    \s:Expand(g:SingleCompile_templates[&filetype]['run'], 1)
    elseif l:user_specified == 0
        let l:run_cmd = s:Expand(s:GetCompilerSingleTemplate(&filetype, 
                    \ s:CompilerTemplate[&filetype]['chosen_compiler'], 'run'),
                    \ 1)
    endif

    if l:async
        let l:ret_val = s:RunAsyncWithMessage(l:run_cmd)
    else
        if executable('tee')
            " if tee is available, then redirect the result to a temp file

            let s:run_result_tempfile = tempname()
            let l:run_cmd = l:run_cmd.
                        \' '.s:GetShellPipe(1).' '.s:run_result_tempfile
        endif

        try
            exec '!'.l:run_cmd
        catch
            call s:ShowMessage('Failed to execute "'.l:run_cmd.'"')
        endtry
    endif

    " switch back to the original directory
    exec 'lcd '.escape(l:cwd, s:CharsEscape)

    " if tee is available, and we are running synchronously, and we want to 
    " show the result window right after the run, then we call 
    " SingleCompile#ViewResult
    if !l:async && executable('tee') &&
                \ g:SingleCompile_showresultafterrun == 1
        call SingleCompile#ViewResult(0)
    endif

    return l:ret_val
endfunction

function! s:CompileRunInternal(comp_param, async) " {{{1

    " if async run is not available, give an error message and stop here.
    if a:async && empty(SingleCompileAsync#GetMode())
        call s:ShowMessage('Async mode is not available for your vim.')
        return
    endif

    " call different functions according to a:async
    if a:async
        let l:CompileFunc = function('SingleCompile#CompileAsync')
    else
        let l:CompileFunc = function('SingleCompile#Compile')
    endif

    if len(a:comp_param) == 1
        let l:compile_result = l:CompileFunc(a:comp_param[0])
    elseif len(a:comp_param) == 2
        let l:compile_result = l:CompileFunc(
                    \a:comp_param[0], a:comp_param[1])
    else
        let l:compile_result = l:CompileFunc()
    endif

    if l:compile_result != 0
        return
    endif


    " run the command and display the following messages only when the process
    " is successfully run.
    if !s:Run(a:async) && a:async
        echo 'SingleCompile: Now the program is running in background.'
        echo 'SingleCompile: you could use :SCViewResultAsync to see the '
                    \.'output if the program has terminated.'
    endif
endfunction

function! SingleCompile#CompileRun(...) " compile and run {{{1
    call s:CompileRunInternal(a:000, 0)
endfunction

function! SingleCompile#CompileRunAsync(...) " {{{1
    " compile and run asynchronously

    call s:CompileRunInternal(a:000, 1)
endfunction

fun! SingleCompile#ChooseCompiler(lang_name, ...) " choose a compiler {{{1

    call s:Initialize()

    if a:0 > 1
        call s:ShowMessage(
                    \'Too many argument for SingleCompile#ChooseCompiler!')
        return
    endif

    if a:0 == 1 " a:0 == 1 means the user has specified a compiler to choose
        if type(a:1) != type('')
            call s:ShowMessage(
                        \'SingleCompile#ChooseCompiler argument error')
            return
        endif

        " If the current langauge template is set, then we check whether it is
        " available on the system; If not, then an error message is given.  If
        " the current langauge template is not set, then we give an error
        " message directly.
        if has_key(s:CompilerTemplate, a:lang_name) && 
                    \has_key(s:CompilerTemplate[a:lang_name], a:1)
            " current language template is set

            let l:detected_compilers = s:DetectCompiler(a:lang_name)

            if count(l:detected_compilers, a:1) == 0 
                " if a:1 is not a detected compiler

                call s:ShowMessage('"'.
                            \a:1.'" is not available on your system.')
                return
            endif

            let s:CompilerTemplate[a:lang_name]['chosen_compiler'] = a:1
        else
            " current language template is not set
            call s:ShowMessage(
                        \'The template of the compiler/interpreter "'.
                        \a:1.'" is not set.')
        endif

        return
    endif

    " when no argument is provided, list all available compilers and
    " interpreters for user to choose
    if a:0 == 0

        " if the language template is not defined for this language, show an
        " error message then return
        if !has_key(s:CompilerTemplate, a:lang_name)
            call s:ShowMessage('Language template for "'.
                        \a:lang_name.'" is not defined on your system.')
            return
        endif

        let l:detected_compilers = s:DetectCompiler(a:lang_name)
        " used to store the detected compilers
        let l:choose_list = [] 
        " used to filled with compiler names to be displayed in front of user
        let l:choose_list_display = [] 

        let l:count = 1

        for some_compiler in keys(s:CompilerTemplate[a:lang_name])
            if some_compiler == 'chosen_compiler'
                continue
            endif

            if count(l:detected_compilers, some_compiler) > 0 
                " if the compiler is detected, then add it to the choose_list,
                " which would be displayed then

                call add(l:choose_list, some_compiler)
                call add(l:choose_list_display, 
                            \l:count.'. '.some_compiler.'('.
                            \s:CompilerTemplate[a:lang_name][some_compiler][
                            \'name'].
                            \')')
                let l:count += 1
            endif
        endfor

        " if l:choose_list is empty, it means no compiler is available for
        " this language
        if empty(l:choose_list)
            call s:ShowMessage(
                        \'No compiler is available for this language!')
            return
        endif

        let l:user_choose = inputlist( extend(['Detected compilers: '],
                    \l:choose_list_display) )
        
        " If user cancels the choosing, then return directly; if user chooses
        " a number which is too big, then echo an empty line first and then
        " show an error message, then return
        if l:user_choose <= 0
            return
        elseif l:user_choose > len(l:choose_list_display) 
            echo ' ' 
            call s:ShowMessage(
                        \'The number you have chosen is invalid.')
            return
        endif

        let s:CompilerTemplate[a:lang_name]['chosen_compiler'] = 
                    \get(l:choose_list, l:user_choose-1)

        return
    endif
endfunction

function! SingleCompile#ViewResult(async) " view the running result {{{1
    " split a window below and put the result there

    " don't show result if s:run_result_tempfile is empty for synchronous run 
    " result and the mode hasn't been set or the process is still running in 
    " background
    if (!a:async && empty(s:run_result_tempfile))
                \|| (a:async
                \&& (empty(SingleCompileAsync#GetMode())
                \|| SingleCompileAsync#IsRunning()))
        return
    endif

    " if the async output cannot be obtained, give an error message and return 
    " directly
    if a:async
        let l:async_out = SingleCompileAsync#GetOutput()
        if type(l:async_out) == type(0)
            call s:ShowMessage(
                        \'Failed to get the output of the '.
                        \'process running asynchronously.')
            return
        endif
    endif

    call s:Initialize()

    " if the __SINGLE_COMPILE_RUN_RESULT__ buffer has already existed, delete
    " it first
    let l:result_bufnr = bufnr('__SINGLE_COMPILE_RUN_RESULT__') 
    if l:result_bufnr != -1
        exec l:result_bufnr.'bdelete'
    endif

    exec 'rightbelow '.g:SingleCompile_resultheight.
                \'split __SINGLE_COMPILE_RUN_RESULT__'

    setl noswapfile buftype=nofile bufhidden=wipe foldcolumn=0 nobuflisted

    setl modifiable
    if a:async
        call append(0, l:async_out)
    else
        call append(0, readfile(s:run_result_tempfile))
    endif
    setl nomodifiable

endfunction

call s:Initialize() " {{{1 call the initialize function



" }}}


let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim703: cc=78
" vim: fdm=marker et ts=4 tw=78 sw=4 fdc=3
