" Copyright (C) 2010-2014 Hong Xu

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

" File: autoload/SingleCompile.vim
" Version: 2.11.0
" check doc/SingleCompile.txt for more information


let s:saved_cpo = &cpo
set cpo&vim


" varibles {{{1
" the dict to store the compiler template
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

function! SingleCompile#GetExecutableSuffix()
    return s:ExecutableSuffix
endfunction

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
    " Before 2.9.3, the return value is: major * 100 + minor * 10 + subminor
    " For example, 2.9.2 is corresponding to 292
    " From 2.10.0, the return value is: major * 1000 + minor * 10 + subminor
    " For example, 2.10.1 is corresponding to 2101
    return 2110
endfunction

" util {{{1
function! SingleCompile#GetDefaultOpenCommand() " {{{2
" Get the default open command. It is "open" on Windows and Mac OS X,
" "xdg-open" on Linux and other UNIX systems.
    if has('win32')
        return 'start'
    elseif has('macunix')
        return 'open'
    elseif has('unix')
        return 'xdg-open'
    else
        return 'open' " We guess 'open' for any other systems
    endif
endfunction

function! s:GetCurrentShell() " {{{2
" Get the name of the current shell according to &shell for UNIX. For example,
" if &shell is '/bin/sh', the return value would be 'sh'.
    if has('unix')
        return strpart(&shell, strridx(&shell, '/') + 1)
    endif
endfunction

function! s:IsShellSh(shell_name) " is the shell Bourne shell? {{2
    if a:shell_name =~ '^sh' ||
                \a:shell_name =~ '^bash' ||
                \a:shell_name =~ '^ksh' ||
                \a:shell_name =~ '^mksh' ||
                \a:shell_name =~ '^pdksh' ||
                \a:shell_name =~ '^zsh'
        return 1
    else
        return 0
    endif
endfunction

function! s:IsShellCsh(shell_name) " is the shell C Shell? {{2
    if a:shell_name =~ '^csh' || a:shell_name =~ '^tcsh'
        return 1
    else
        return 0
    endif
endfunction

function! s:IsShellFish(shell_name) " is the shell FISH shell {{2
    return a:shell_name =~ '^fish'
endfunction

function! s:GetShellLastExitCodeVariable() " {{{2
    " Get the variable that presents the exit code of last command.

    if has('unix')

        let l:cur_shell = s:GetCurrentShell()

        if s:IsShellCsh(l:cur_shell) || s:IsShellFish(l:cur_shell)
            return '$status'
        elseif s:IsShellSh(l:cur_shell)
            return '$?'
        else
            return ''
        endif

    elseif has('win32')
        return '$?'
    endif

endfunction

function! s:GetShellPipe(tee_used) " {{{2
    " get the shell pipe command according to it's platform. If a:tee_used is
    " set to nonzero, then the shell pipe contains "tee", otherwise "tee"
    " wouldn't be contained in the return value.

    if has('unix')

        let l:cur_shell = s:GetCurrentShell()

        if s:IsShellCsh(l:cur_shell)
            if a:tee_used
                return '|& tee'
            else
                return '>&'
            endif
        elseif s:IsShellSh(l:cur_shell) || s:IsShellFish(l:cur_shell)
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
        if executable('tee') && a:tee_used && g:SingleCompile_usetee
            return '2>&1 | tee'
        else
            return '>%s 2>&1'
        endif
    endif

endfunction
function! s:Expand(str, ...) " expand the string{{{2
    " the second argument is optional. If it is given and it is zero, then
    " we thought we don't need any quote; otherwise, we use double quotes on
    " Windows and single quotes on all other systems.

    let l:quote_needed = 1
    if a:0 > 1
        call s:ShowMessage('s:Expand argument error.')
        return ''
    elseif a:0 == 1
        if !a:1
            let l:quote_needed = 0
        endif
    endif

    let l:rep_dict = {
                \'\$(FILE_NAME)\$': '%',
                \'\$(FILE_PATH)\$': '%:p',
                \'\$(FILE_TITLE)\$': '%:r',
                \'\$(FILE_EXEC)\$': '%:p:r',
                \'\$(FILE_RUN)\$': '%:p:r'}
    let l:rep_dict_prefix = {
                \'\$(FILE_NAME)\$': '',
                \'\$(FILE_PATH)\$': '',
                \'\$(FILE_TITLE)\$': '',
                \'\$(FILE_EXEC)\$': '',
                \'\$(FILE_RUN)\$': ''}
    let l:rep_dict_suffix = {
                \'\$(FILE_NAME)\$': '',
                \'\$(FILE_PATH)\$': '',
                \'\$(FILE_TITLE)\$': '',
                \'\$(FILE_EXEC)\$': '',
                \'\$(FILE_RUN)\$': ''}

    if has('win32')
        let l:rep_dict_prefix['\$(FILE_RUN)\$'] = ''
        let l:rep_dict_suffix['\$(FILE_EXEC)\$'] = '.exe'
        let l:rep_dict_suffix['\$(FILE_RUN)\$'] = '.exe'
    elseif has('unix')
        let l:rep_dict_prefix['\$(FILE_RUN)\$'] = './'
        let l:rep_dict_suffix['\$(FILE_EXEC)\$'] = ''
        let l:rep_dict_suffix['\$(FILE_RUN)\$'] = ''
    endif


    let l:str = a:str
    for one_key in keys(l:rep_dict)
        let l:rep_string = l:rep_dict_prefix[one_key] .
                    \ expand(l:rep_dict[one_key]) .
                    \ l:rep_dict_suffix[one_key]

        " on win32, replace the backslash with '/'
        if has('win32')
            let l:rep_string = substitute(l:rep_string, '/', '\\', 'g')
        endif

        let l:rep_string = escape(l:rep_string, '\')
        if l:quote_needed && match(l:rep_string, ' ') != -1

            if has('win32')
                let l:rep_string = '"'.l:rep_string.'"'
            else
                let l:rep_string = "'".l:rep_string."'"
            endif

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

function! s:PushEnvironmentVaribles() " {{{2
    " push environment varibles into stack. Win32 only.

    if !exists('s:environment_varibles_list') ||
                \ type(s:environment_varibles_list) != type([])
        unlet! s:environment_varibles_list
        let s:environment_varibles_list = []
    endif

    let l:environment_varibles_dic = {}

    let l:environment_varibles_string = system('set')

    for line in split(l:environment_varibles_string, '\n')

        " find the '=' first. The left part is environment varible's name, the
        " right part is the value
        let l:eq_pos = match(line, '=')
        if l:eq_pos == -1
            continue
        endif

        let l:key = strpart(line, 0, l:eq_pos)
        let l:val = strpart(line, l:eq_pos + 1)

        let l:environment_varibles_dic[l:key] = l:val
    endfor

    call add(s:environment_varibles_list, l:environment_varibles_dic)
endfunction

function! s:PopEnvironmentVaribles() " {{{2
    " pop environment varibles out of the stack. Win32 only.

    if !exists('s:environment_varibles_list') ||
                \ type(s:environment_varibles_list) != type([]) ||
                \ empty(s:environment_varibles_list)
        return 0
    endif

    let l:environment_varibles_dic = remove(
                \ s:environment_varibles_list,
                \ len(s:environment_varibles_list) - 1)

    for l:key in keys(l:environment_varibles_dic)
        silent! exec 'let $' . l:key . "='" .
                    \ substitute(l:environment_varibles_dic[l:key],
                    \ "'", "''", 'g') . "'"
    endfor
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

function! SingleCompile#PredoWatcom(compiling_info) " watcom pre-do {{{2
    let s:old_path = $PATH
    let $PATH = $WATCOM.s:PathSeperator.'binnt'.s:EnvSeperator.
                \$WATCOM.s:PathSeperator.'binw'.s:EnvSeperator.
                \$PATH
    return a:compiling_info
endfunction

function! SingleCompile#PredoGcc(compiling_info) " gcc pre-do {{{2
    if has('unix')
        return s:AddLmIfMathH(a:compiling_info)
    else
        return a:compiling_info
    endif
endfunction

function! SingleCompile#PredoSolStudioC(compiling_info) " solaris studio C/C++ pre-do {{{2
    return s:AddLmIfMathH(a:compiling_info)
endfunction

function! SingleCompile#PredoClang(compiling_info) " clang Predo {{{2
    if has('unix')
        return s:AddLmIfMathH(a:compiling_info)
    else
        return a:compiling_info
    endif
endfunction

function! SingleCompile#PredoMicrosoftVC(compiling_info) " MSVC Predo {{{2

    call s:PushEnvironmentVaribles()

    " to get the result environment varibles, we need to write a temp batch
    " file and call it.
    let l:tmpbat = tempname() . '.bat'
    call writefile(['@echo off', 'call "%VS'.
                \str2nr(strpart(a:compiling_info['command'], 2)).
                \'COMNTOOLS%..\..\VC\vcvarsall.bat"', 'set'], l:tmpbat)
    let l:environment_varibles_string = system(l:tmpbat)

    " Set the environment varibles
    for l:line in split(l:environment_varibles_string, '\n')
        let l:eq_pos = match(l:line, '=')

        if l:eq_pos == -1
            continue
        endif

        silent! exec 'let $' . strpart(l:line, 0, l:eq_pos) . "='" .
                    \ substitute(strpart(l:line, l:eq_pos + 1),
                    \ "'", "''", 'g') . "'"
    endfor

    let l:new_compiling_info = a:compiling_info
    let l:new_compiling_info['command'] = 'cl'

    return l:new_compiling_info
endfunction

" post-do functions {{{1
function! SingleCompile#PostdoWatcom(compiling_info) " watcom pre-do {{{2
    let $PATH = s:old_path
    return a:compiling_info
endfunction

function! SingleCompile#PostdoMicrosoftVC(not_used_arg) " MSVC post-do {{{2
    call s:PopEnvironmentVaribles()
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

function! SingleCompile#DetectWatcom(compiling_command) " {{{2
    let l:watcom_command =
                \s:DetectCompilerGenerally(a:compiling_command)
    if l:watcom_command != 0
        return l:watcom_command
    endif

    if $WATCOM != ''
        return $WATCOM.'\binnt\'.a:compiling_command
    endif
endfunction

function! SingleCompile#DetectMicrosoftVC(compiling_command) " {{{2
    " the compiling_command should be cl_vcversion, such as cl80, cl100, etc.

    " return 0 if not starting with 'cl'
    if strpart(a:compiling_command, 0, 2) != 'cl'
        return 0
    endif

    " get the version of vc
    let l:vc_version = strpart(a:compiling_command, 2)

    " if we have VSXXCOMNTOOLS environment variable, and
    " %VSXXCOMNTOOLS%\..\..\VC\BIN\cl.exe is executable, and
    " %VSXXCOMNTOOLS%\..\..\VC\vcvarsall.bat is executable, MSVC is detected
    exec 'let l:vs_common_tools = $VS'.l:vc_version.'COMNTOOLS'

    if !empty(l:vs_common_tools) &&
                \ executable(l:vs_common_tools.'..\..\VC\BIN\cl.exe') &&
                \ executable(l:vs_common_tools.'..\..\VC\vcvarsall.bat')
        return a:compiling_command
    else
        return 0
    endif
endfunction

function! SingleCompile#DetectIe(not_used_arg) " {{{2
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

    if !exists('g:SingleCompile_quickfixwindowposition') ||
                \type(g:SingleCompile_quickfixwindowposition) != type('')
        unlet! g:SingleCompile_quickfixwindowposition
        let g:SingleCompile_quickfixwindowposition = 'botright'
    end

    if !exists('g:SingleCompile_resultsize') ||
                \type(g:SingleCompile_resultsize) != type(0) ||
                \g:SingleCompile_resultsize <= 0
        unlet! g:SingleCompile_resultsize
        let g:SingleCompile_resultsize = 5
    endif

    if !exists('g:SingleCompile_split')
        let g:SingleCompile_split = 'split'
    endif

    if !exists('g:SingleCompile_showquickfixiferror') ||
                \type(g:SingleCompile_showquickfixiferror) != type(0)
        unlet! g:SingleCompile_showquickfixiferror
        let g:SingleCompile_showquickfixiferror = 0
    endif

    if !exists('g:SingleCompile_showquickfixifwarning') ||
                \type(g:SingleCompile_showquickfixifwarning) != type(0)
        unlet! g:SingleCompile_showquickfixifwarning
        let g:SingleCompile_showquickfixifwarning =
                    \g:SingleCompile_showquickfixiferror
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

    if !exists('g:SingleCompile_usetee') ||
                \type(g:SingleCompile_usetee) != type(0)
        unlet! g:SingleCompile_usetee
        let g:SingleCompile_usetee = 1
    endif

    if !exists('g:SingleCompile_silentcompileifshowquickfix') ||
                \type(g:SingleCompile_silentcompileifshowquickfix) != type(0)
        unlet! g:SingleCompile_silentcompileifshowquickfix
        let g:SingleCompile_silentcompileifshowquickfix = 0
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

    " initialize builtin templates
    if has('win32')
        let g:SingleCompile_common_run_command = '$(FILE_TITLE)$.exe'
        let g:SingleCompile_common_out_file = '$(FILE_TITLE)$.exe'
    else
        let g:SingleCompile_common_run_command = './$(FILE_TITLE)$'
        let g:SingleCompile_common_out_file = '$(FILE_TITLE)$'
    endif

    for builtin_filetype in [
                \ 'ada',
                \ 'bash',
                \ 'c',
                \ 'cmake',
                \ 'cpp',
                \ 'coffee',
                \ 'cs',
                \ 'csh',
                \ 'd',
                \ 'dosbatch',
                \ 'erlang',
                \ 'fortran',
                \ 'go',
                \ 'haskell',
                \ 'html',
                \ 'idlang',
                \ 'java',
                \ 'javascript',
                \ 'ksh',
                \ 'lisp',
                \ 'ls',
                \ 'lua',
                \ 'make',
                \ 'markdown',
                \ 'matlab',
                \ 'objc',
                \ 'pascal',
                \ 'perl',
                \ 'php',
                \ 'python',
                \ 'qml',
                \ 'r',
                \ 'rst',
                \ 'ruby',
                \ 'rust',
                \ 'scala',
                \ 'sh',
                \ 'tcl',
                \ 'tcsh',
                \ 'tex',
                \ 'vb',
                \ 'vim',
                \ 'xhtml',
                \ 'zsh']
        exec 'call SingleCompile#templates#' .
                    \ builtin_filetype . '#Initialize()'
    endfor
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
                \'detect_func', 'pre-do', 'priority', 'post-do', 'out-file',
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

function! SingleCompile#SetPriority(lang_name, compiler, priority) " {{{2
    " set priority

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler,
                \ 'priority', a:priority)
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

function! SingleCompile#SetTemplate(lang_name, stype, string,...) " {{{1
    " set the template. if the '...' is nonzero, this function will not
    " override the corresponding template if there is an existing template

    if a:0 > 1
        call s:ShowMessage('Too many argument for '.
                    \'SingleCompile#SetTemplate function')
        return
    endif

    if a:0 == 0 || a:1 == 0
        let l:override = 0
    else
        let l:override = 1
    endif

    if a:stype == 'command'
        let l:stype = 'detect_func_arg'
    else
        let l:stype = a:stype
    endif

    " Set the name any way
    call s:SetCompilerSingleTemplate(a:lang_name,
                \'user_defined_compiler_using_old_style_function',
                \'name', 'user_defined_compiler_using_old_style_function', 1)

    let l:compiler_dict = s:CompilerTemplate[a:lang_name][
                \ 'user_defined_compiler_using_old_style_function']

    " Use general detect_func
    if !has_key(l:compiler_dict, 'detect_func')
        call SingleCompile#SetDetectFunc(a:lang_name,
                    \'user_defined_compiler_using_old_style_function',
                    \function("s:DetectCompilerGenerally"))
    endif

    " Set the template we want to set
    call s:SetCompilerSingleTemplate(a:lang_name,
                \'user_defined_compiler_using_old_style_function',
                \l:stype, a:string, l:override)

    if has_key(l:compiler_dict, 'name') &&
                \ has_key(l:compiler_dict, 'detect_func') &&
                \ has_key(l:compiler_dict, 'detect_func_arg') &&
                \ has_key(l:compiler_dict, 'flags') &&
                \ has_key(l:compiler_dict, 'run')
        call SingleCompile#ChooseCompiler(a:lang_name,
                    \ 'user_defined_compiler_using_old_style_function')
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

    let l:chosen_compiler =
                \s:CompilerTemplate[a:filetype_name]['chosen_compiler']
    return (!has_key(
                \s:CompilerTemplate[a:filetype_name][l:chosen_compiler],
                \'run')
                \ || substitute(
                \s:CompilerTemplate[a:filetype_name][l:chosen_compiler]
                \['run'],
                \' ', '', "g") == '')
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
    " Return 0 for compiling language successfully compiled;
    " Return 1 for compiling language failed to be compiled;
    " Return 2 for interpreting language successfully run;
    " Return 3 for interpreting language failed to be run.

    call s:Initialize()
    let l:toret = 0

    " whether we should run asynchronously if we are working with an
    " interpreting language
    let l:async = a:async && !empty(SingleCompileAsync#GetMode())
    if !l:async && executable('tee') && g:SingleCompile_usetee
                \ && g:SingleCompile_showresultafterrun == 1
        let l:show_result_after_run = 1
    else
        let l:show_result_after_run = 0
    endif

    " save current file type. Don't use &filetype directly because after
    " 'make' and quickfix is working and the error is in another file,
    " sometimes the value of &filetype may be incorrect.
    let l:cur_filetype = &filetype

    " Save the filetype to a script variable so it can be used by s:Run()
    let s:cur_filetype = l:cur_filetype

    " if current filetype is an empty string, show an error message and
    " return.
    if l:cur_filetype == ''
        call s:ShowMessage(
                    \"Current buffer's filetype is not specified. ".
                    \"Use \" :help 'filetype' \" command to see more details".
                    \" if you don't know what filetype is.")
        return -1
    endif

    " Check whether the language template is available
    if !(has_key(s:CompilerTemplate, l:cur_filetype) &&
                \type(s:CompilerTemplate[l:cur_filetype]) == type({}))
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

    " detect compilers
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

    " save current working directory
    let l:cwd = getcwd()
    " switch current work directory to the file's directory
    silent lcd %:p:h

    " If current language is not interpreting language, check the last
    " modification time of the file, whose name is the value of the 'out-file'
    " key. If the last modification time of that file is earlier than the last
    " modification time of current buffer's file, don't compile.
    if !g:SingleCompile_alwayscompile
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
    elseif len(a:arg_list) == 2 && has_key(
                \s:CompilerTemplate[l:cur_filetype][
                \s:CompilerTemplate[l:cur_filetype]['chosen_compiler']],
                \'flags')
        " if there are two arguments, it means append the provided argument to
        " the flag defined in the template

        let l:compile_flags = s:GetCompilerSingleTemplate(l:cur_filetype,
                    \s:CompilerTemplate[l:cur_filetype]['chosen_compiler'],
                    \'flags').' '.a:arg_list[1]
    elseif len(a:arg_list) == 0 && has_key(
                \s:CompilerTemplate[l:cur_filetype][
                \s:CompilerTemplate[l:cur_filetype]['chosen_compiler']],
                \'flags')
        let l:compile_flags = s:GetCompilerSingleTemplate(l:cur_filetype,
                    \s:CompilerTemplate[l:cur_filetype]['chosen_compiler'],
                    \'flags')
    else
        " if len(a:arg_list) is zero and 'flags' is not defined, assign '' to
        " let l:compile_flags

        let l:compile_flags = ''
    endif


    if match(l:compile_flags, '\$(FILE_PATH)\$') == -1 &&
                \match(l:compile_flags, '\$(FILE_NAME)\$') == -1
        let l:compile_flags = l:compile_flags.' $(FILE_PATH)$'
    endif
    let l:compile_args = s:Expand(l:compile_flags)

    " call the pre-do function if set
    if has_key(s:CompilerTemplate[l:cur_filetype][l:chosen_compiler],
                \ 'pre-do')
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
                call s:ShowMessage('Error! Return value is '.v:shell_error)
                if s:IsLanguageInterpreting(l:cur_filetype)
                    let l:toret = 3
                else
                    let l:toret = 1
                endif
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

            " call :compiler! command to set vim compiler. We use :compiler!
            " but not :compiler because cgetexpr command uses global option
            " value of errorformat
            call s:SetGlobalVimCompiler(l:cur_filetype, l:chosen_compiler)

            let l:exit_code_tempfile = tempname()
            let s:run_result_tempfile = tempname()
            " The output is put into s:run_result_tempfile, and exit code is
            " written into l:exit_code_tempfile. The command should be
            " something like this on bash:
            "   !(compiler_cmd compile_args; echo $? >tmp1) | tee tmp2
            exec (l:show_result_after_run ? 'silent ' : '').
                        \ '!('.l:compile_cmd.' '.l:compile_args.'; '.
                        \ 'echo '.s:GetShellLastExitCodeVariable().' >'.
                        \ l:exit_code_tempfile.') '.s:GetShellPipe(1).' '.
                        \ s:run_result_tempfile

            " if the exit code couldn't be obtained or the exit code is not 0,
            " l:toret is set to 3 (this return value is for interpreting
            " language only, means interpreting failed)
            let l:exit_code_str = readfile(l:exit_code_tempfile)
            if (len(l:exit_code_str) < 1) ||
                        \ (len(l:exit_code_str) >= 1 &&
                        \ str2nr(l:exit_code_str[0]))
                echo ' '
                call s:ShowMessage(
                            \ 'Interpreter exit code is '.l:exit_code_str[0])

                let l:toret = 3
            endif

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

        " call :compiler command to set vim compiler
        call s:SetVimCompiler(l:cur_filetype, l:chosen_compiler)

        let &l:makeprg = l:compile_cmd
        let &l:shellpipe = s:GetShellPipe(0)
        let l:prefix_args = ''
        let l:silentcompile = g:SingleCompile_silentcompileifshowquickfix &&
                    \ g:SingleCompile_showquickfixiferror &&
                    \ has("gui_running")

        if l:silentcompile
            let l:prefix_args = 'silent '
        endif
        exec l:prefix_args.'make'.' '.l:compile_args

        " check whether compiling is successful, if not, show the return value
        " with error message highlighting and set the return value to 1
        if v:shell_error != 0
            if !l:silentcompile
                echo ' '
                call s:ShowMessage(
                            \ 'Compiler exit code is '.v:shell_error)
            endif
            let l:toret = 1
        endif

        " set back makeprg and shellpipe
        let &l:makeprg = l:old_makeprg
        let &l:shellpipe = l:old_shellpipe
        let &l:errorformat = l:old_errorformat
    endif

    " if it's interpreting language, and l:toret has not been set, then return
    " 2 (means do not call run if user uses SCCompileRun command
    if l:toret == 0 && s:IsLanguageInterpreting(l:cur_filetype)
        let l:toret = 2
    endif

    " call the post-do function if set
    if has_key(s:CompilerTemplate[l:cur_filetype][l:chosen_compiler],
                \'post-do')
        let l:TmpFunc = s:CompilerTemplate[l:cur_filetype][l:chosen_compiler][
                    \'post-do']
        call l:TmpFunc({'command': l:compile_cmd, 'args': l:compile_args})
    endif


    " switch back to the original directory
    exec 'lcd '.escape(l:cwd, s:CharsEscape)

    " show the quickfix window if error occurs, quickfix is used and
    " g:SingleCompile_showquickfixiferror is set to nonzero
    if g:SingleCompile_showquickfixiferror && s:ShouldQuickfixBeUsed()
        " We have error
        if l:toret == 1 || l:toret == 3
            " workaround when the compiler file is broken
            exec g:SingleCompile_quickfixwindowposition . ' cope'
        " We may have warning
        elseif g:SingleCompile_showquickfixifwarning
            exec g:SingleCompile_quickfixwindowposition . ' cw'
        endif
    endif

    " if we are running an interpreting language source file, and we want to
    " show the result window right after the run, and we are not running it
    " asynchronously, then we show or hide the result
    if l:show_result_after_run
        if l:toret == 2
            call SingleCompile#ViewResult(0)
            redraw!
        elseif l:toret == 1 || l:toret == 3
            call SingleCompile#CloseViewResult()
        endif
    endif

    return l:toret
endfunction

function! s:CompareCompilerPriority(compiler1, compiler2) " {{{1
    " Compare the priorities of two compiler. The lang_name is determinted by
    " s:lang_name_compare_compiler_priority (if it is presented) or &filetype

    if exists('s:lang_name_compare_compiler_priority')
        let l:lang_name = s:lang_name_compare_compiler_priority
    else
        let l:lang_name = &filetype
    endif

    if has_key(s:CompilerTemplate[l:lang_name][a:compiler1], 'priority')
        let l:compiler1_priority =
                    \ s:CompilerTemplate[l:lang_name][a:compiler1]['priority']
    else
        let l:compiler1_priority = 100
    endif

    if has_key(s:CompilerTemplate[l:lang_name][a:compiler2], 'priority')
        let l:compiler2_priority =
                    \ s:CompilerTemplate[l:lang_name][a:compiler2]['priority']
    else
        let l:compiler2_priority = 100
    endif

    return l:compiler1_priority == l:compiler2_priority ? 0 : (
                \ l:compiler1_priority > l:compiler2_priority ? 1 : -1)
endfunction

function! s:DetectCompiler(lang_name) " {{{1
    " to detect compilers for one language. Return available compilers sorted
    " by priority

    let l:toret = []

    " call the compiler detection function to get the compilation command
    for some_compiler in keys(s:CompilerTemplate[a:lang_name])
        if some_compiler == 'chosen_compiler'
            continue
        endif

        " ignore this compiler if things are not all available (name,
        " detect_func, detect_func_arg, flags, run)
        let l:compiler_dict = s:CompilerTemplate[a:lang_name][some_compiler]
        if !(has_key(l:compiler_dict, 'name') &&
                    \ has_key(l:compiler_dict, 'detect_func') &&
                    \ has_key(l:compiler_dict, 'detect_func_arg') &&
                    \ has_key(l:compiler_dict, 'flags') &&
                    \ has_key(l:compiler_dict, 'run'))
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

    " sort detected compilers by priority
    let s:lang_name_compare_compiler_priority = a:lang_name
    call sort(l:toret, 's:CompareCompilerPriority')

    return l:toret
endfunction

function! s:Run(async) " {{{1
    " if async is non-zero, then run asynchronously

    " Get the current filetype. We do not use &filetype because quickfix may
    " open another file automatically, which may cause the filetype changed to
    " an incorrect value.
    let l:cur_filetype = s:cur_filetype

    let l:ret_val = 0

    call s:Initialize()

    " whether we should use async mode
    let l:async = a:async && !empty(SingleCompileAsync#GetMode())
    if !l:async && executable('tee') && g:SingleCompile_usetee
                \ && g:SingleCompile_showresultafterrun == 1
        let l:show_result_after_run = 1
    else
        let l:show_result_after_run = 0
    endif

    if !(has_key(s:CompilerTemplate[l:cur_filetype][
                \s:CompilerTemplate[l:cur_filetype]['chosen_compiler']],
                \'run'))
        call s:ShowMessage('Fail to run!')
        return 1
    endif

    " save current working directory
    let l:cwd = getcwd()
    silent lcd %:p:h

    let l:run_cmd = s:Expand(s:GetCompilerSingleTemplate(l:cur_filetype,
                \ s:CompilerTemplate[l:cur_filetype]['chosen_compiler'],
                \ 'run'), 1)

    if l:async
        let l:ret_val = s:RunAsyncWithMessage(l:run_cmd)
    else
        if executable('tee') && g:SingleCompile_usetee
            " if tee is available, and we enabled the use of "tee", then
            " redirect the result to a temp file

            let s:run_result_tempfile = tempname()
            let l:run_cmd = l:run_cmd.
                        \' '.s:GetShellPipe(1).' '.s:run_result_tempfile
        endif

        try
            exec (l:show_result_after_run ? 'silent ' : '').'!'.l:run_cmd
        catch
            call s:ShowMessage('Failed to execute "'.l:run_cmd.'"')
        endtry
    endif

    " switch back to the original directory
    exec 'lcd '.escape(l:cwd, s:CharsEscape)

    " if tee is available, and we are running synchronously, and we want to
    " show the result window right after the run, then we call
    " SingleCompile#ViewResult
    if l:show_result_after_run
        call SingleCompile#ViewResult(0)
        redraw!
    endif

    return l:ret_val
endfunction

function! s:CompileRunInternal(comp_param, async) " {{{1

    " save the current path, thus if quickfix switches to another file, we can
    " still switch back to execute future code correctly
    let l:cur_filepath = expand('%:p')

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



    let l:cur_filepath2 = expand('%:p')

    if l:cur_filepath != l:cur_filepath2
        exec 'edit ' . l:cur_filepath
    endif

    " run the command and display the following messages only when the process
    " is successfully run.
    if !s:Run(a:async) && a:async
        echo 'SingleCompile: Now the program is running in background.'
        echo 'SingleCompile: you could use :SCViewResultAsync to see the '
                    \.'output if the program has terminated.'
    endif

    if l:cur_filepath != l:cur_filepath2
        exec 'edit ' . l:cur_filepath2
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

        " If the current language template is set, then we check whether it is
        " available on the system; If not, then an error message is given.  If
        " the current language template is not set, then we give an error
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

        if !has_key(s:CompilerTemplate[a:lang_name], 'chosen_compiler')
            let s:CompilerTemplate[a:lang_name]['chosen_compiler'] =
                        \ get(l:detected_compilers, 0)
        endif

        for some_compiler in sort(keys(s:CompilerTemplate[a:lang_name]))
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

        " display current compiler/interpreter
        echo "Current Compiler/Interpreter: " .
                    \ s:CompilerTemplate[a:lang_name]['chosen_compiler']

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

    let l:result_bufnr = bufnr('__SINGLE_COMPILE_RUN_RESULT__')

    " if the __SINGLE_COMPILE_RUN_RESULT__ buffer doesn't exist, make one
    " else clear it, but leave it there to be refilled
    if l:result_bufnr == -1
        exec 'rightbelow '.g:SingleCompile_resultsize.
                    \g:SingleCompile_split.' __SINGLE_COMPILE_RUN_RESULT__'
        setl noswapfile buftype=nofile bufhidden=wipe foldcolumn=0 nobuflisted
    else
        let l:result_bufwinnr = bufwinnr(l:result_bufnr)
        exec l:result_bufwinnr.'wincmd w'
        let l:save_cursor = getpos(".")
        setl modifiable
        normal! ggdG
        setl nomodifiable
    endif


    setl modifiable
    if a:async
        call append(0, l:async_out)
    else
        call append(0, readfile(s:run_result_tempfile))
    endif
    nnoremap <buffer> q :q<CR>
    setl nomodifiable

    if l:result_bufnr != -1
        call setpos('.', l:save_cursor)
    endif

    exec 'wincmd p'
endfunction

function! SingleCompile#CloseViewResult() " close the last result {{{1
    let l:result_bufnr = bufnr('__SINGLE_COMPILE_RUN_RESULT__')
    if l:result_bufnr != -1
        exec bufwinnr(l:result_bufnr).'wincmd w'
        if l:result_bufnr == bufnr('%') " if we got there
            quit
        endif
    endif
endfunction

call s:Initialize() " {{{1 call the initialize function



" }}}


let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim703: cc=78
" vim: fdm=marker et ts=4 tw=78 sw=4 fdc=3
