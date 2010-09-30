" File: autoload/SingleCompile.vim
" Version: 1.2.2
" check doc/SingleCompile.txt for more information


let s:save_cpo = &cpo
set cpo&vim


" the dic to store the compiler template
let s:CompilerTemplate = {}
let g:SingleCompile_templates = {}



function! SingleCompile#GetVersion() " get the script version {{{1
    return 122
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
endfunction

function! SingleCompile#SetCompilerTemplate(lang_name, compiler, compiler_name, detect_func_arg, flags, run_command, ...) " {{{1
    " set compiler's template
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

function! s:DetectCompilerGenerally(compile_command)
    " the general function of compiler detection. The principle is to search
    " the environment varible PATH and some special directory

    if executable(a:compile_command) == 1
        return a:compile_command
    endif

    if has('unix')
        if executable('/usr/bin/'.a:compile_command) == 1
            return '/usr/bin/'.a:compile_command
        endif
        if executable('/usr/local/bin/'.a:compile_command) == 1
            return '/usr/local/bin/'.a:compile_command
        endif
        if executable('/bin/'.a:compile_command) == 1
            return '/bin/'.a:compile_command
        endif
    endif
endfunction

function! s:GetCompilerSingleTemplate(lang_name, compiler_name, key)
    return s:CompilerTemplate[a:lang_name][a:compiler_name][a:key]
endfunction

function! s:SetCompilerSingleTemplate(lang_name, compiler_name, key, value, ...) " {{{1
    " set the template. if the '...' is nonzero, this function will not override the corresponding template if there is an existing template 

    if a:0 > 1
        echohl ErrorMsg | echo 'too many argument for SingleCompile#SetCompilerSingleTemplate function' | echohl None
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
        echohl ErrorMsg | echo 'too many argument for SingleCompile#SetTemplate function' | echohl None
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
        echohl ErrorMsg | echo a:message | echohl None
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
                    \ || substitute(s:CompilerTemplate[a:filetype_name][l:chosen_compiler]['run'], ' ', '', "g") )
    endif
endfunction

function! SingleCompile#Compile(...) " compile only {{{1
    call s:Intialize()
    let l:toret = 0

    " if the following condition is met, then use the user specified command
    if has_key(g:SingleCompile_templates,&filetype) && has_key(g:SingleCompile_templates[&filetype],'command')
        let l:user_specified = 1
    elseif has_key(s:CompilerTemplate, &filetype)
        let l:user_specified = 0
    else
        echohl Error | echo 'Language template is not defined on your system. Please define the language template.' | echohl None
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
                echohl Error | echo 'No compiler is detected on your system!' | echohl None
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

    " if a:0 is zero and 'flags' is not defined, assign '' to let l:compile_flags
    if a:0 == 1
        let l:compile_flags = a:1
    elseif l:user_specified == 1 && has_key(g:SingleCompile_templates[&filetype],'flags')
        let l:compile_flags = g:SingleCompile_templates[&filetype]['flags']
    elseif l:user_specified == 0 && has_key(s:CompilerTemplate[&filetype][ s:CompilerTemplate[&filetype]['chosen_compiler'] ], 'flags')
        let l:compile_flags = s:GetCompilerSingleTemplate(&filetype, s:CompilerTemplate[&filetype]['chosen_compiler'], 'flags')
    else
        let l:compile_flags = ''
    endif

    if g:SingleCompile_enablequickfix == 0
                \ || !has('quickfix') 
                \ || ( s:IsLanguageInterpreting(&filetype) && !has('unix') )
        " if quickfix is not enabled for this plugin or the language is an interpreting language not in unix, then don't use quickfix
        exec '!'.l:compile_cmd.' '.l:compile_flags.' %:p'
        if v:shell_error != 0
            let l:toret = 1
        endif

    elseif has('unix') && s:IsLanguageInterpreting(&filetype) " use quickfix for interpreting language in unix
        " change the makeprg and shellpipe temporarily
        let l:old_makeprg = &makeprg
        let l:old_shellpipe = &shellpipe
        exec 'setlocal makeprg='.l:compile_cmd

        " change shellpipe according to the shell type
        if &shell =~ 'sh' || &shell =~ 'ksh' || &shell =~ 'zsh' || &shell =~ 'bash'
            exec 'setlocal shellpipe=2>&1\|\ tee'
        elseif &shell =~ 'csh' || &shell =~ 'tcsh' 
            exec 'setlocal shellpipe=\|&\ tee'
        else
            exec 'setlocal shellpipe=\|\ tee'
        endif

        exec 'make'.' '.l:compile_flags.' %:p'

        " set back makeprg and shellpipe
        exec 'setlocal makeprg='.l:old_makeprg
        exec 'setlocal shellpipe='.escape(l:old_shellpipe,' |')

    else " use quickfix for compiling language

        " change the makeprg and shellpipe temporarily 
        let l:old_makeprg = &makeprg
        let l:old_shellpipe = &shellpipe
        exec 'setlocal makeprg='.l:compile_cmd
        exec 'setlocal shellpipe=>%s\ 2>&1'
        exec 'make'.' '.l:compile_flags.' %:p'
        " check is compiling successful
        if v:shell_error != 0
            let l:toret = 1
        endif
        " set back makeprg and shellpipe
        exec 'setlocal makeprg='.l:old_makeprg
        exec 'setlocal shellpipe='.escape(l:old_shellpipe,' |')
    endif

    " switch back to the original directory
    exec 'cd '.l:curcwd
    return l:toret
endfunction


function! s:DetectCompiler(lang_name) " to detect compilers for one language. Return available compilers{{{1
    let l:toret = []

    " call the compiler detection function to get the compilation command
    for some_compiler in keys(s:CompilerTemplate[&filetype])
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
        call s:ShowMessage('Fail to run!')
    endif

    let l:curcwd=getcwd()
    cd %:p:h

    if l:user_specified == 1
        let l:run_cmd = g:SingleCompile_templates[&filetype]['run']
    elseif l:user_specified == 0
        let l:run_cmd = s:GetCompilerSingleTemplate(&filetype, s:CompilerTemplate[&filetype]['chosen_compiler'], 'run')
    endif

    exec '!'.l:run_cmd

    exec 'cd '.l:curcwd

    return
endfunction

function! SingleCompile#CompileRun(...) " compile and run {{{1
    if a:0 > 0
        let l:compileResult = SingleCompile#Compile(a:1)
    else
        let l:compileResult = SingleCompile#Compile()
    endif

    if l:compileResult != 0
        return
    endif
    call s:Run()
endfunction

" templates {{{1

" c
if has('win32') || has('win64')
    call SingleCompile#SetCompilerTemplate('c', 'gcc', 'GNU C Compiler', 'gcc', '-o %<', '%<')
else
    call SingleCompile#SetCompilerTemplate('c', 'gcc', 'GNU C Compiler', 'gcc', '-o %<', './'.'%<')
endif

" cpp
if has('win32') || has('win64')
    call SingleCompile#SetCompilerTemplate('cpp', 'g++', 'GNU C++ Compiler', 'g++', '-o %<', '%<')
else
    call SingleCompile#SetCompilerTemplate('cpp', 'g++', 'GNU C++ Compiler', 'g++', '-o %<', './'.'%<')
endif

" java
call SingleCompile#SetCompilerTemplate('java', 'java', 'Sun JDK', 'javac', '', 'java %<')

" fortran
if has('unix')
    call SingleCompile#SetCompilerTemplate('fortran', 'gfortran', 'GNU Fortran Compiler', 'gfortran', '-o %<', './'.'%<')
    call SingleCompile#SetCompilerTemplate('fortran', 'g77', 'GNU Fortran 77 Compiler', 'g77', '-o %<', './'.'%<')
elseif has('win32') || has('win64')
    call SingleCompile#SetCompilerTemplate('fortran', 'g77', 'GNU Fortran 77 Compiler', 'g77', '-o %<', '%<')
endif

" shell
call SingleCompile#SetCompilerTemplate('sh', 'shell', 'UNIX Shell', 'sh', '', '')

" dosbatch
call SingleCompile#SetCompilerTemplate('dosbatch', 'dosbatch', 'DOS Batch', '', '', '')

" html
if has('win32') || has('win64')
    call SingleCompile#SetCompilerTemplate('html', 'ie', 'Microsoft Internet Explorer', 'iexplore', '', '')
endif
call SingleCompile#SetCompilerTemplate('html', 'firefox', 'Mozilla Firefox', 'firefox', '', '')

" xhtml
if has('win32') || has('win64')
    call SingleCompile#SetCompilerTemplate('xhtml', 'ie', 'Microsoft Internet Explorer', 'iexplore', '', '')
endif
call SingleCompile#SetCompilerTemplate('xhtml', 'firefox', 'Mozilla Firefox', 'firefox', '', '')

" vbs
call SingleCompile#SetCompilerTemplate('vb', 'vb', 'VB Script Interpreter', 'cscript', '', '')

" latex
if has('unix')
    call SingleCompile#SetCompilerTemplate('tex', 'texlive', 'Tex Live', 'latex', '', 'xdvi %<.dvi')
elseif has('win32') || has('win64')
    call SingleCompile#SetCompilerTemplate('tex', 'texlive', 'Tex Live', 'latex', '', 'dviout %<.dvi')
endif

" plain tex
if has('unix')
    call SingleCompile#SetCompilerTemplate('plaintex', 'texlive', 'Tex Live', 'latex', '', 'xdvi %<.dvi')
elseif has('win32') || has('win64')
    call SingleCompile#SetCompilerTemplate('plaintex', 'texlive', 'Tex Live', 'latex', '', 'dviout %<.dvi')
endif

" python
call SingleCompile#SetCompilerTemplate('python', 'python', 'Python Interpreter', 'python', '', '')

" perl
call SingleCompile#SetCompilerTemplate('perl', 'perl', 'Perl Interpreter', 'perl', '', '')

" ruby
call SingleCompile#SetCompilerTemplate('ruby', 'ruby', 'Ruby Interpreter', 'ruby', '', '')

" lua
call SingleCompile#SetCompilerTemplate('lua', 'lua', 'Lua Interpreter', 'lua', '', '')

" Makefile
call SingleCompile#SetCompilerTemplate('make', 'make', 'GNU Make', 'make', '-f', '')

" cmake
call SingleCompile#SetCompilerTemplate('cmake', 'cmake', 'cmake', 'cmake', '', '')


" }}}


let &cpo = s:save_cpo
" vim: fdm=marker et
