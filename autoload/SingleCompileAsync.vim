" File: autoload/SingleCompileAsync.vim
" Version: 2.7.3
" check doc/SingleCompile.txt for more information


let s:saved_cpo = &cpo
set cpo&vim

let s:cur_mode = ''

function! SingleCompileAsync#SetMode(mode) " {{{1

    " only set to the new mode if no mode is set before.
    if empty(s:cur_mode)
        let s:cur_mode = a:mode
    endif
endfunction

function! SingleCompileAsync#IsRunning() " {{{1
    " check is there a process running in background.
    " Return 1 means there is a process running in background,
    " return 0 means there is no process running in background,
    " return -1 if mode hasn't been set

    if empty(s:cur_mode)
        return 0
    endif

    return 0
endfunction

function! SingleCompileAsync#Run(run_command) " {{{1
    " run a new command.
    " Return -1 if mode hasn't been set;
    " return 1 if a process is running in background;
    " return 0 means the command is run successfully.

    if empty(s:cur_mode)
        return -1
    endif

    if SingleCompileAsync#IsRunning() == 1
        return 1
    endif


endfunction

function! SingleCompileAsync#Terminate() " {{{1
    " terminate current background process

    " Return -1 if mode hasn't been set;
    " return 1 if no process is running in background;
    " return 0 means terminating the process successfully.

    if empty(s:cur_mode)
        return -1
    endif

    if SingleCompileAsync#IsRunning() == 0
        return 1
    endif


endfunction
" }}}

let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim: fdm=marker et ts=4 tw=78 sw=4 fdc=3
