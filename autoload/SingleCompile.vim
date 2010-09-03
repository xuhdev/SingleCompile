" File: autoload/SingleCompile.vim
" Version: 1.2.1
" check doc/SingleCompile.txt for more information


let s:save_cpo = &cpo
set cpo&vim

function! SingleCompile#GetVersion() " get the script version {{{1
    return 120
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
    return (!has_key(g:SingleCompile_templates[a:filetype_name],'run') 
                \ || substitute(g:SingleCompile_templates[a:filetype_name]['run'], ' ','',"g") == '')
endfunction

function! SingleCompile#Compile(...) " compile only {{{1
    call s:Intialize()
    let l:toret = 0

    if !has_key(g:SingleCompile_templates,&filetype)
        call s:ShowMessage('SingleCompile: Your file type is not supported on this system! Define the template by yourself. See doc/SingleCompile.txt for more information.')
        return -1
    elseif !has_key(g:SingleCompile_templates[&filetype],'command')
        call s:ShowMessage('SingleCompile: No compile command is defined for this file type!')
        return -1
    endif

    " switch current work directory to the file's directory
    let l:curcwd=getcwd()
    cd %:p:h

    " if autowrite is set and the buffer has been modified, then save
    if g:SingleCompile_autowrite != 0 && &modified != 0
        exec 'w'
    endif

    let l:compile_cmd = g:SingleCompile_templates[&filetype]['command']
    " if a:0 is zero and 'flags' is not defined, assign '' to let l:compile_flags
    if a:0 == 1
        let l:compile_flags = a:1
    elseif has_key(g:SingleCompile_templates[&filetype],'flags')
        let l:compile_flags = g:SingleCompile_templates[&filetype]['flags']
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

function! s:Run() " {{{1
    call s:Intialize()

    if !has_key(g:SingleCompile_templates,&filetype)
        return
    endif

    if !has_key(g:SingleCompile_templates[&filetype],'run')
        call s:ShowMessage('SingleCompile: No run command is defined for this file type!')
        return
    endif

    let l:curcwd=getcwd()
    cd %:p:h

    let l:run_cmd=g:SingleCompile_templates[&filetype]['run']

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

" }}}

let &cpo = s:save_cpo
" vim: fdm=marker
