" File: autoload/SingleCompile.vim
" Version: 0.8
" check plugin/SingleCompile.vim and doc/SingleCompile.txt for more information


let s:save_cpo = &cpo
set cpo&vim

function! SingleCompile#GetVersion() " get the script version {{{1
    return 80
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

    if !exists('g:SingleCompile_templates') || type(g:SingleCompile_templates) != type({})
        unlet! g:SingleCompile_templates
        let g:SingleCompile_templates={}
    endif

    if !has_key(g:SingleCompile_templates,a:langname)
        let g:SingleCompile_templates[a:langname]={}
    elseif type(g:SingleCompile_templates[a:langname]) != type({})
        unlet! g:SingleCompile_templates[a:langname]
        let g:SingleCompile_templates[a:langname]={}
    endif

    if !has_key(g:SingleCompile_templates[a:langname],a:stype)
        let g:SingleCompile_templates[a:langname][a:stype] = a:string
    elseif type(g:SingleCompile_templates[a:langname][a:stype]) != type('')
        unlet! g:SingleCompile_templates[a:langname][a:stype]
        let g:SingleCompile_templates[a:langname][a:stype] = a:string
    else
        if a:0 == 0 || a:1 == 0
            let g:SingleCompile_templates[a:langname][a:stype] = a:string
        endif
    endif
endfunction


function! s:ShowMessage(message) "{{{1

    if g:SingleCompile_usedialog == 0 || !((has('gui_running') && has('dialog_gui')) || has('dialog_con'))
        echohl ErrorMsg | echo a:message | echohl None
    else
        call confirm(a:message)
    endif

endfunction

function! SingleCompile#Compile() " compile only {{{1
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

    if g:SingleCompile_autowrite != 0
        exec 'w'
    endif

    let l:compile_cmd = g:SingleCompile_templates[&filetype]['command']
    " if 'flags' is not defined, use '' as let l:compile_flags = g:SingleCompile_templates[&filetype]['flags']
    if has_key(g:SingleCompile_templates[&filetype],'flags')
        let l:compile_flags = g:SingleCompile_templates[&filetype]['flags']
    else
        let l:compile_flags = ''
    endif

    if g:SingleCompile_enablequickfix == 0 || !has_key(g:SingleCompile_templates[&filetype],'run') || substitute(g:SingleCompile_templates[&filetype]['run'], ' ','',"g") == '' || !has('quickfix') " if quickfix is not enabled for this plugin and the run command of the language is empty(which means this is an interpreting language
        exec '!'.l:compile_cmd.' '.l:compile_flags.' %:p'
        if v:shell_error != 0
            let l:toret = 1
        endif
    else
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

function! SingleCompile#CompileRun() " compile and run {{{1
    if SingleCompile#Compile() != 0
        return
    endif
    call s:Run()
endfunction

" }}}

let &cpo = s:save_cpo
" vim: fdm=marker
