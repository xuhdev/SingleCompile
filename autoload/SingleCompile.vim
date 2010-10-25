" File: autoload/SingleCompile.vim
" Version: 2.1
" check doc/SingleCompile.txt for more information


let s:save_cpo = &cpo
set cpo&vim


" the dic to store the compiler template
let s:CompilerTemplate = {}
let g:SingleCompile_templates = {}
let s:TemplateIntialized = 0



function! SingleCompile#GetVersion() " get the script version {{{1
    return 210
endfunction

" compiler detect functions {{{1
function! s:DetectCompilerGenerally(compile_command) " {{{2
    " the general function of compiler detection. The principle is to search
    " the environment varible PATH and some special directory

    if has('unix') || has('macunix')
        let l:list_to_detect = [expand(a:compile_command),
                    \expand('/usr/bin/'.a:compile_command), 
                    \expand('/usr/local/bin/'.a:compile_command),
                    \expand('/bin/'.a:compile_command),
                    \expand('~/bin/'.a:compile_command)
                    \]
    else
        let l:list_to_detect = [expand(a:compile_command)]
    endif

    for cmd in l:list_to_detect
        if executable(cmd) == 1
            return cmd
        endif
    endfor

    return 0
endfunction

function! s:DetectIe(not_used_arg) " {{{2
    if executable('iexplore')
        return 'iexplore'
    endif

    if has('win32') || has('win64')
        for iepath in ['C:\Program Files\Internet Explorer\iexplore',
                    \ 'D:\Program Files\Internet Explorer\iexplore',
                    \ 'E:\Program Files\Internet Explorer\iexplore',
                    \ 'F:\Program Files\Internet Explorer\iexplore',
                    \ 'G:\Program Files\Internet Explorer\iexplore']
            if executable(iepath)
                return "\"".iepath."\""
            endif
        endfor
    endif
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

function! s:Intialize() "{{{1
    if !exists('g:SingleCompile_autowrite')
        let g:SingleCompile_autowrite = 1
    endif

    if !exists('g:SingleCompile_usedialog')
        let g:SingleCompile_usedialog = 0
    endif

    if !exists('g:SingleCompile_enablequickfix')
        let g:SingleCompile_enablequickfix = 1
    endif


    if s:TemplateIntialized == 0
        
        let s:TemplateIntialized = 1

        " templates {{{2
        if has('win32') || has('win64') || has('os2')
            let s:common_run_command = '%<'
        else
            let s:common_run_command = './'.'%<'
        endif

        " c
        call SingleCompile#SetCompilerTemplate('c', 'open-watcom', 'Open Watcom C/C++32 Compiler', 'wcl386', '', s:common_run_command)
        if has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('c', 'msvc', 'Microsoft Visual C++', 'cl', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('c', 'bcc', 'Borland C++ Builder', 'bcc32', '-o "%<"', s:common_run_command)
        endif
        call SingleCompile#SetCompilerTemplate('c', 'gcc', 'GNU C Compiler', 'gcc', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('c', 'icc', 'Intel C++ Compiler', 'icc', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('c', 'pcc', 'Portable C Compiler', 'pcc', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('c', 'tcc', 'Tiny C Compiler', 'tcc', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('c', 'ch', 'SoftIntegration Ch', 'ch', '', '')
        if has('unix') || has('macunix')
            call SingleCompile#SetCompilerTemplate('c', 'cc', 'UNIX C Compiler', 'cc', '-o "%<"', s:common_run_command)
        endif
        if has('unix')
            call SingleCompile#SetCompilerTemplate('c', 'sol-studio', 'Sun C Compiler (Sun Solaris Studio)', 'suncc', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('c', 'open64', 'Open64 C Compiler', 'opencc', '-o "%<"', s:common_run_command)
        endif

        " cpp
        call SingleCompile#SetCompilerTemplate('cpp', 'open-watcom', 'Open Watcom C/C++32 Compiler', 'wcl386', '', s:common_run_command)
        if has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('cpp', 'msvc', 'Microsoft Visual C++', 'cl', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('cpp', 'bcc', 'Borland C++ Builder', 'bcc32', '-o "%<"', s:common_run_command)
        endif
        call SingleCompile#SetCompilerTemplate('cpp', 'g++', 'GNU C++ Compiler', 'g++', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('cpp', 'icc', 'Intel C++ Compiler', 'icc', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('cpp', 'ch', 'SoftIntegration Ch', 'ch', '', '')
        if has('unix')
            call SingleCompile#SetCompilerTemplate('cpp', 'sol-studio', 'Sun C++ Compiler (Sun Solaris Studio)', 'sunCC', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('cpp', 'open64', 'Open64 C++ Compiler', 'openCC', '-o "%<"', s:common_run_command)
        endif

        " java
        call SingleCompile#SetCompilerTemplate('java', 'sunjdk', 'Sun Java Development Kit', 'javac', '', 'java "%<"')
        call SingleCompile#SetCompilerTemplate('java', 'gcj', 'GNU Java Compiler', 'gcj', '', 'java "%<"')

        " fortran
        if has('unix') || has('macunix')
            call SingleCompile#SetCompilerTemplate('fortran', 'gfortran', 'GNU Fortran Compiler', 'gfortran', '-o "%<"', s:common_run_command)
        endif
        if has('unix')
            call SingleCompile#SetCompilerTemplate('fortran', 'sol-studio-f77', 'Sun Fortran 77 Compiler (Sun Solaris Studio)', 'sunf77', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('fortran', 'sol-studio-f90', 'Sun Fortran 90 Compiler (Sun Solaris Studio)', 'sunf90', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('fortran', 'sol-studio-f95', 'Sun Fortran 95 Compiler (Sun Solaris Studio)', 'sunf95', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('fortran', 'open64-f90', 'Open64 Fortran 90 Compiler', 'openf90', '-o "%<"', s:common_run_command)
            call SingleCompile#SetCompilerTemplate('fortran', 'open64-f95', 'Open64 Fortran 95 Compiler', 'openf95', '-o "%<"', s:common_run_command)
        endif
        if has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('fortran', 'ftn95', 'Silverfrost FTN95', 'ftn95', '$source_file$ /LINK', s:common_run_command)
        endif
        call SingleCompile#SetCompilerTemplate('fortran', 'g77', 'GNU Fortran 77 Compiler', 'g77', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('fortran', 'ifort', 'Intel Fortran Compiler', 'ifort', '-o "%<"', s:common_run_command)
        call SingleCompile#SetCompilerTemplate('fortran', 'open-watcom', 'Open Watcom Fortran 77/32 Compiler', 'wfl386', '', s:common_run_command)

        " lisp
        call SingleCompile#SetCompilerTemplate('lisp', 'clisp', 'GNU CLISP', 'clisp', '', '')
        call SingleCompile#SetCompilerTemplate('lisp', 'ecl', 'Embeddable Common-Lisp', 'ecl', '-shell', '')

        " shell
        call SingleCompile#SetCompilerTemplate('sh', 'shell', 'UNIX Shell', 'sh', '', '')

        " dosbatch
        call SingleCompile#SetCompilerTemplate('dosbatch', 'dosbatch', 'DOS Batch', '', '', '')

        " html
        call SingleCompile#SetCompilerTemplate('html', 'firefox', 'Mozilla Firefox', 'firefox', '', '')
        call SingleCompile#SetCompilerTemplate('html', 'chrome', 'Google Chrome', 'google-chrome', '', '')
        call SingleCompile#SetCompilerTemplate('html', 'opera', 'Opera', 'opera', '', '')
        if has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('html', 'ie', 'Microsoft Internet Explorer', 'iexplore', '', '', function('s:DetectIe'))
        else
            call SingleCompile#SetCompilerTemplate('html', 'ie', 'Microsoft Internet Explorer', 'iexplore', '', '')
        endif

        " xhtml
        call SingleCompile#SetCompilerTemplate('xhtml', 'firefox', 'Mozilla Firefox', 'firefox', '', '')
        call SingleCompile#SetCompilerTemplate('xhtml', 'chrome', 'Google Chrome', 'google-chrome', '', '')
        call SingleCompile#SetCompilerTemplate('xhtml', 'opera', 'Opera', 'opera', '', '')
        if has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('xhtml', 'ie', 'Microsoft Internet Explorer', 'iexplore', '', '', function('s:DetectIe'))
        else
            call SingleCompile#SetCompilerTemplate('xhtml', 'ie', 'Microsoft Internet Explorer', 'iexplore', '', '')
        endif

        " vbs
        call SingleCompile#SetCompilerTemplate('vb', 'vbs', 'VB Script Interpreter', 'cscript', '', '')

        " latex
        if has('unix') || has('macunix')
            call SingleCompile#SetCompilerTemplate('tex', 'texlive', 'Tex Live', 'latex', '', 'xdvi "%<.dvi"')
        elseif has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('tex', 'texlive', 'Tex Live', 'latex', '', 'dviout "%<.dvi"')
            call SingleCompile#SetCompilerTemplate('tex', 'miktex', 'MiKTeX', 'latex', '', 'yap "%<.dvi"')
        endif

        " plain tex
        if has('unix') || has('macunix')
            call SingleCompile#SetCompilerTemplate('plaintex', 'texlive', 'Tex Live', 'latex', '', 'xdvi "%<.dvi"')
        elseif has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('plaintex', 'texlive', 'Tex Live', 'latex', '', 'dviout "%<.dvi"')
            call SingleCompile#SetCompilerTemplate('plaintex', 'miktex', 'MiKTeX', 'latex', '', 'yap "%<.dvi"')
        endif

        " python
        call SingleCompile#SetCompilerTemplate('python', 'cpython', 'CPython', 'python', '', '')
        call SingleCompile#SetCompilerTemplate('python', 'jython', 'Jython', 'jython', '', '')
        call SingleCompile#SetCompilerTemplate('python', 'pypy', 'PyPy', 'pypy', '', '')
        call SingleCompile#SetCompilerTemplate('python', 'cpython3', 'CPython 3', 'python3', '', '')

        " perl
        call SingleCompile#SetCompilerTemplate('perl', 'perl', 'Perl Interpreter', 'perl', '', '')

        " ruby
        call SingleCompile#SetCompilerTemplate('ruby', 'ruby', 'Ruby Interpreter', 'ruby', '', '')

        " lua
        call SingleCompile#SetCompilerTemplate('lua', 'lua', 'Lua Interpreter', 'lua', '', '')

        " Makefile
        call SingleCompile#SetCompilerTemplate('make', 'gmake', 'GNU Make', 'gmake', '-f', '', function('s:DetectGmake'))
        call SingleCompile#SetCompilerTemplate('make', 'mingw32-make', 'MinGW32 Make', 'mingw32-make', '-f', '')
        if has('win32') || has('win64')
            call SingleCompile#SetCompilerTemplate('make', 'nmake', 'Microsoft Program Maintenance Utility', 'nmake', '-f', '')
        endif

        " javascript
        call SingleCompile#SetCompilerTemplate('javascript', 'rhino', 'Rhino', 'rhino', '', '')


        " cmake
        call SingleCompile#SetCompilerTemplate('cmake', 'cmake', 'cmake', 'cmake', '', '')

        " 2}}}

    endif
endfunction

function! SingleCompile#SetCompilerTemplate(lang_name, compiler, compiler_name, detect_func_arg, flags, run_command, ...) " {{{1
    " set compiler's template

    call s:Intialize()

    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'name', a:compiler_name)
    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'detect_func_arg', a:detect_func_arg)
    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'flags', a:flags)
    call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'run', a:run_command)
    if a:0 == 0
        call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'detect_func', function("s:DetectCompilerGenerally"))
    else
        call s:SetCompilerSingleTemplate(a:lang_name, a:compiler, 'detect_func', a:1)
    endif
endfunction


function! s:GetCompilerSingleTemplate(lang_name, compiler_name, key) " {{{1
    return s:CompilerTemplate[a:lang_name][a:compiler_name][a:key]
endfunction

function! s:SetCompilerSingleTemplate(lang_name, compiler_name, key, value, ...) " {{{1
    " set the template. if the '...' is nonzero, this function will not override the corresponding template if there is an existing template 

    if a:0 > 1
        call s:ShowMessage('too many argument for SingleCompile#SetCompilerSingleTemplate function')
        return
    endif

    " if the key a:lang_name does not exist, create it
    if !has_key(s:CompilerTemplate,a:lang_name)
        let s:CompilerTemplate[a:lang_name] = {}
    elseif type(s:CompilerTemplate[a:lang_name]) != type({})
        unlet! s:CompilerTemplate[a:lang_name]
        let s:CompilerTemplate[a:lang_name] = {}
    endif

    " if a:compiler_name does not exist, create it
    if !has_key(s:CompilerTemplate[a:lang_name],a:compiler_name)
        let s:CompilerTemplate[a:lang_name][a:compiler_name] = {}
    elseif type(s:CompilerTemplate[a:lang_name][a:compiler_name]) != type({})
        unlet! s:CompilerTemplate[a:lang_name][a:compiler_name]
        let s:CompilerTemplate[a:lang_name][a:compiler_name] = {}
    endif

    " if a:key does not exist, create it
    if !has_key(s:CompilerTemplate[a:lang_name][a:compiler_name], a:key)
        let s:CompilerTemplate[a:lang_name][a:compiler_name][a:key] = a:value
    elseif a:0 == 0 || a:1 == 0 " if the ... from the argument is 0 or the additional argument does not exist
        let s:CompilerTemplate[a:lang_name][a:compiler_name][a:key] = a:value
    endif
endfunction

function! SingleCompile#SetTemplate(langname,stype,string,...) " set the template. if the '...' is nonzero, this function will not override the corresponding template if there is an existing template {{{1
    if a:0 > 1
        call s:ShowMessage('too many argument for SingleCompile#SetTemplate function')
        return
    endif

    " if g:SingleCompile_templates does not exist or it is not a dic, then
    " make g:SingleCompile_templates a dic
    if !exists('g:SingleCompile_templates') || type(g:SingleCompile_templates) != type({})
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
    elseif a:0 == 0 || a:1 == 0 " if the ... from the argument is 0 or the additional argument does not exist
        let g:SingleCompile_templates[a:langname][a:stype] = a:string
    endif
endfunction


function! s:ShowMessage(message) "{{{1

    if g:SingleCompile_usedialog == 0 || !((has('gui_running') && has('dialog_gui')) || has('dialog_con'))
        call s:ShowMessage(a:message)
    else
        call confirm(a:message)
    endif

endfunction

function! s:IsLanguageInterpreting(filetype_name) "{{{1 tell if a language is an interpreting language, reutrn 1 if yes, 0 if no
    if has_key(g:SingleCompile_templates, a:filetype_name)
        return (!has_key(g:SingleCompile_templates[a:filetype_name],'run') 
                    \ || substitute(g:SingleCompile_templates[a:filetype_name]['run'], ' ','',"g") == '')
    else
        let l:chosen_compiler = s:CompilerTemplate[a:filetype_name]['chosen_compiler']
        return (!has_key(s:CompilerTemplate[a:filetype_name][l:chosen_compiler], 'run')
                    \ || substitute(s:CompilerTemplate[a:filetype_name][l:chosen_compiler]['run'], ' ', '', "g") == '')
    endif
endfunction

function! s:ShouldQuickfixBeUsed() " tell whether quickfix sould be used{{{1
    if g:SingleCompile_enablequickfix == 0
                \ || !has('quickfix') 
                \ || ( s:IsLanguageInterpreting(&filetype) && !has('unix') )
        return 0
    else
        return 1
    endif
endfunction

function! SingleCompile#Compile(...) " compile only {{{1
    call s:Intialize()
    let l:toret = 0

    " if the following condition is met, then use the user specified command
    if has_key(g:SingleCompile_templates,&filetype) && has_key(g:SingleCompile_templates[&filetype],'command')
        let l:user_specified = 1
    elseif has_key(s:CompilerTemplate, &filetype) && type(s:CompilerTemplate[&filetype]) == type({})
        let l:user_specified = 0
    else
        call s:ShowMessage('Language template for "'.&filetype.'" is not defined on your system.')
        return -1
    endif


    " if autowrite is set and the buffer has been modified, then save
    if g:SingleCompile_autowrite != 0 && &modified != 0
        write
    endif

    " if user specified is zero, then detect compilers
    if l:user_specified == 0
        if !has_key(s:CompilerTemplate[&filetype], 'chosen_compiler')
            let detected_compilers = s:DetectCompiler(&filetype)
            " if detected_compilers is empty, then no compiler is detected
            if empty(detected_compilers)
                call s:ShowMessage('SingleCompile: No compiler is detected on your system!')
                return -1
            endif

            let s:CompilerTemplate[&filetype]['chosen_compiler'] = get(detected_compilers, 0)
        endif
        let l:compile_cmd = s:GetCompilerSingleTemplate(&filetype, s:CompilerTemplate[&filetype]['chosen_compiler'], 'command')
    elseif l:user_specified == 1
        let l:compile_cmd = g:SingleCompile_templates[&filetype]['command']
    endif

    " switch current work directory to the file's directory
    let l:curcwd=getcwd()
    cd %:p:h

    if a:0 == 1 " if there is only one argument, it means use this argument as the compilation flag
        let l:compile_flags = a:1
    elseif a:0 == 2 && l:user_specified == 1 && has_key(g:SingleCompile_templates[&filetype],'flags') " if there is two arguments, it means append the provided argument to the flag defined in the template
        let l:compile_flags = g:SingleCompile_templates[&filetype]['flags'].' '.a:2
    elseif a:0 == 0 && l:user_specified == 1 && has_key(g:SingleCompile_templates[&filetype],'flags')
        let l:compile_flags = g:SingleCompile_templates[&filetype]['flags']
    elseif a:0 == 2 && l:user_specified == 0 && has_key(s:CompilerTemplate[&filetype][ s:CompilerTemplate[&filetype]['chosen_compiler'] ], 'flags') " if there is two arguments, it means append the provided argument to the flag defined in the template

        let l:compile_flags = s:GetCompilerSingleTemplate(&filetype, s:CompilerTemplate[&filetype]['chosen_compiler'], 'flags').' '.a:2
    elseif a:0 == 0 && l:user_specified == 0 && has_key(s:CompilerTemplate[&filetype][ s:CompilerTemplate[&filetype]['chosen_compiler'] ], 'flags')
        let l:compile_flags = s:GetCompilerSingleTemplate(&filetype, s:CompilerTemplate[&filetype]['chosen_compiler'], 'flags')
    else  " if a:0 is zero and 'flags' is not defined, assign '' to let l:compile_flags
        let l:compile_flags = ''
    endif

    " set the file name to be compiled
    let l:file_to_compile = expand('%:p')

    " on win32, win64, and os2, replace the backslash in l:file_to_compile
    " with '/'
    if has('win32') || has('win64') || has('os2')
        let l:file_to_compile = substitute(l:file_to_compile, '/', '\\', 'g')
    endif

    if match(l:file_to_compile, ' ') != -1 " if there are spaces in the file name, surround it with quotes
        let l:file_to_compile = '"'.l:file_to_compile.'"'
    endif
    
    if match(l:compile_flags, '\$source_file\$') == -1
        let l:compile_flags = l:compile_flags.' $source_file$'
    endif
    let l:compile_args = substitute(l:compile_flags, '\$source_file\$', escape(l:file_to_compile,'\'), 'g')

    if s:ShouldQuickfixBeUsed() == 0
        " if quickfix is not enabled for this plugin or the language is an interpreting language not in unix, then don't use quickfix
        exec '!'.l:compile_cmd.' '.l:compile_args
        if v:shell_error != 0
            let l:toret = 1
        endif

    elseif has('unix') && s:IsLanguageInterpreting(&filetype) " use quickfix for interpreting language in unix
        " change the makeprg and shellpipe temporarily
        let l:old_makeprg = &makeprg
        let l:old_shellpipe = &shellpipe
        let &l:makeprg = l:compile_cmd

        " change shellpipe according to the shell type
        if &shell =~ 'sh' || &shell =~ 'ksh' || &shell =~ 'zsh' || &shell =~ 'bash'
            exec 'setlocal shellpipe=2>&1\|\ tee'
        elseif &shell =~ 'csh' || &shell =~ 'tcsh' 
            exec 'setlocal shellpipe=\|&\ tee'
        else
            exec 'setlocal shellpipe=\|\ tee'
        endif

        exec 'make'.' '.l:compile_args

        " set back makeprg and shellpipe
        exec 'setlocal makeprg='.l:old_makeprg
        exec 'setlocal shellpipe='.escape(l:old_shellpipe,' |')


    else " use quickfix for compiling language

        " change the makeprg and shellpipe temporarily 
        let l:old_makeprg = &makeprg
        let l:old_shellpipe = &shellpipe
        let &l:makeprg = l:compile_cmd
        exec 'setlocal shellpipe=>%s\ 2>&1'
        exec 'make'.' '.l:compile_args
        " check is compiling successful
        if v:shell_error != 0
            let l:toret = 1
        endif
        " set back makeprg and shellpipe
        exec 'setlocal makeprg='.l:old_makeprg
        exec 'setlocal shellpipe='.escape(l:old_shellpipe,' |')
    endif

    " if it's interpreting language, then return 2 (means do not call run if
    " user uses SCCompileRun command
    if s:IsLanguageInterpreting(&filetype)
        let l:toret = 2
    endif

    " switch back to the original directory
    exec 'cd '.'"'.l:curcwd.'"'
    return l:toret
endfunction


function! s:DetectCompiler(lang_name) " to detect compilers for one language. Return available compilers{{{1
    let l:toret = []

    " call the compiler detection function to get the compilation command
    for some_compiler in keys(s:CompilerTemplate[a:lang_name])
        if some_compiler == 'chosen_compiler'
            continue
        endif
        call s:SetCompilerSingleTemplate(a:lang_name, some_compiler, 'command', 
                    \s:CompilerTemplate[a:lang_name][some_compiler]['detect_func'](s:CompilerTemplate[a:lang_name][some_compiler]['detect_func_arg']) )

        " if the type of s:CompilerTemplate[&filetype]['command'] returned
        " by the detection function is not a string, then we may think
        " that this compiler cannot be detected
        if type(s:CompilerTemplate[a:lang_name][some_compiler]['command']) == type('')
            call add(l:toret, some_compiler)
        endif
    endfor

    return l:toret
endfunction

function! s:Run() " {{{1
    call s:Intialize()

    if has_key(g:SingleCompile_templates,&filetype) && has_key(g:SingleCompile_templates[&filetype],'run')
        let l:user_specified = 1
    elseif has_key(s:CompilerTemplate[&filetype][ s:CompilerTemplate[&filetype]['chosen_compiler'] ],'run')
        let l:user_specified = 0
    else
        call s:ShowMessage('SingleCompile: Fail to run!')
    endif

    let l:curcwd=getcwd()
    cd %:p:h

    if l:user_specified == 1
        let l:run_cmd = g:SingleCompile_templates[&filetype]['run']
    elseif l:user_specified == 0
        let l:run_cmd = s:GetCompilerSingleTemplate(&filetype, s:CompilerTemplate[&filetype]['chosen_compiler'], 'run')
    endif

    let l:run_cmd = '"'.l:run_cmd.'"'

    exec '!'.l:run_cmd

    exec 'cd '.'"'.l:curcwd.'"'

    return
endfunction

function! SingleCompile#CompileRun(...) " compile and run {{{1
    if a:0 == 1
        let l:compileResult = SingleCompile#Compile(a:1)
    elseif a:0 == 2
        let l:compileResult = SingleCompile#Compile(a:1, a:2)
    else
        let l:compileResult = SingleCompile#Compile()
    endif

    if l:compileResult != 0
        return
    endif
    call s:Run()
endfunction

function! SingleCompile#ChooseCompiler(lang_name, ...) " choose a compiler {{{1

    call s:Intialize()

    if a:0 > 1
        call s:ShowMessage('SingleCompile: Too many argument for SingleCompile#ChooseCompiler!')
        return
    endif

    if a:0 == 1 " a:0 == 1 means the user has specified a compiler to choose
        if type(a:1) != type('')
            call s:ShowMessage('SingleCompile: SingleCompile#ChooseCompiler argument error')
            return
        endif
        if has_key(s:CompilerTemplate, a:lang_name) && has_key(s:CompilerTemplate[a:lang_name], a:1)
            let l:detected_compilers = s:DetectCompiler(a:lang_name)
          
            if count(l:detected_compilers, a:1) == 0 " if a:1 is not a detected compiler
                call s:ShowMessage('SingleCompile: '.a:1.' is not available on your system.')
                return
            endif

            let s:CompilerTemplate[a:lang_name]['chosen_compiler'] = a:1
        endif

        return
    endif

    if a:0 == 0
        if !has_key(s:CompilerTemplate, a:lang_name)
            return
        endif

        let l:detected_compilers = s:DetectCompiler(a:lang_name)
        let l:choose_list = [] " used to remember the compilers
        let l:choose_list_display = [] " used to filled with compiler names to be displayed in front of user
        let l:count = 1
        for some_compiler in keys(s:CompilerTemplate[a:lang_name])
            if some_compiler == 'chosen_compiler'
                continue
            endif

            if count(l:detected_compilers, some_compiler) > 0 " if the compiler is detected, then display it
                call add(l:choose_list, some_compiler)
                call add(l:choose_list_display, l:count.'. '.some_compiler.'('.s:CompilerTemplate[a:lang_name][some_compiler]['name'].')')
                let l:count += 1
            endif
        endfor

        if empty(l:choose_list)
            call s:ShowMessage('SingleCompile: No compiler is available for this language!')
            return
        endif

        let l:user_choose = inputlist( extend(['Detected compilers: '], l:choose_list_display) )
        
        " if user does not choose a valid option
        if l:user_choose <= 0
            return
        endif

        let s:CompilerTemplate[a:lang_name]['chosen_compiler'] = get(l:choose_list, l:user_choose-1)

        return
    endif
endfunction

call s:Intialize() " {{{1 call the initialize function



" }}}


let &cpo = s:save_cpo
" vim: fdm=marker et
