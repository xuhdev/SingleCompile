" File: autoload/SingleCompileAsync.vim
" Version: 2.7.3
" check doc/SingleCompile.txt for more information


let s:saved_cpo = &cpo
set cpo&vim

let s:cur_mode = ''
let s:mode_dict = {}

" python mode functions {{{1

function! s:InitializePython() " {{{2
    " the Initialize function of python

    if !has('python')
        return 'Python interface is not available in this Vim.'
    endif

python << EEOOFF

try:
    import vim
    import subprocess
except ImportError:
    vim.command("return ''")

class SingleCompileAsync:
    sub_proc = None

EEOOFF
endfunction

function! s:IsRunningPython() " {{{2
    " The IsRunning function of python

python << EEOOFF

if SingleCompileAsync.sub_proc != None and \
        SingleCompileAsync.sub_proc.poll() == None:
    vim.command('let l:ret_val = 1')
else:
    vim.command('let l:ret_val = 0')

EEOOFF

    return l:ret_val
endfunction

function! s:RunPython(run_command) " {{{2
    " The Run function of python

    let l:ret_val = 0

python << EEOOFF

try:
    SingleCompileAsync.sub_proc = subprocess.Popen(vim.eval('a:run_command'),
        shell = True, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
except OSError, ValueError:
    vim.command('let l:ret_val = 2')

EEOOFF

    return l:ret_val
endfunction

function! s:TerminatePython() " {{{2
    " The Terminate function of python

    let l:ret_val = 0

python << EEOOFF

try:
    SingleCompileAsync.sub_proc.terminate()
except OSError:
    vim.command('let l:ret_val = 2')

EEOOFF

    return l:ret_val
endfunction

function! s:GetOutputPython() " {{{2
    " The GetOutput function of python

python << EEOOFF
try:
    SingleCompileAsync.out = SingleCompileAsync.sub_proc.communicate()[0]
except OSError, ValueError:
    vim.command('let l:ret_val = 2')
else:
    vim.command("let l:ret_val = '" +
            SingleCompileAsync.out.replace("'", "''") + "'")
EEOOFF

    if type(l:ret_val) == type('')
        let l:ret_list = split(l:ret_val, "\n")
        unlet! l:ret_val
        let l:ret_val = l:ret_list
    endif

    return l:ret_val
endfunction

function! SingleCompileAsync#Initialize(mode) " {{{1

    " only set to the new mode if no mode is set before.
    if !empty(s:cur_mode)
        return 2
    endif

    let s:cur_mode = a:mode

    " set function refs to dict
    if a:mode == 'python'
        let s:mode_dict['Initialize'] = function('s:InitializePython')
        let s:mode_dict['IsRunning'] = function('s:IsRunningPython')
        let s:mode_dict['Run'] = function('s:RunPython')
        let s:mode_dict['Terminate'] = function('s:TerminatePython')
        let s:mode_dict['GetOutput'] = function('s:GetOutputPython')
    endif

    " call the initialization function
    let l:init_result = s:mode_dict['Initialize']()

    if type(l:init_result) == type('')
        echohl ErrorMsg | echo l:init_result | echohl None
        return 1
    elseif type(l:init_result) == type(0) && l:init_result != 0
        echohl ErrorMsg | echo 'SingleCompileAsnyc initialization error.'
                    \| echohl None
        return 1
    endif

    return 0
endfunction

function! SingleCompileAsync#IsRunning() " {{{1
    " check is there a process running in background.
    " Return 1 means there is a process running in background,
    " return 0 means there is no process running in background,
    " return -1 if mode hasn't been set,
    " return other values if failed to check whether the process is running.

    if empty(s:cur_mode)
        return 0
    endif

    return s:mode_dict['IsRunning']()
endfunction

function! SingleCompileAsync#Run(run_command) " {{{1
    " run a new command.
    " Return -1 if mode hasn't been set;
    " return 1 if a process is running in background;
    " return 0 means the command is run successfully;
    " return other values means the command is not run successfully.

    if empty(s:cur_mode)
        return -1
    endif

    if SingleCompileAsync#IsRunning() == 1
        return 1
    endif

    return s:mode_dict['Run'](a:run_command)
endfunction

function! SingleCompileAsync#Terminate() " {{{1
    " terminate current background process

    " Return -1 if mode hasn't been set;
    " return 1 if no process is running in background;
    " return 0 means terminating the process successfully;
    " return other values means failed to terminate.

    if empty(s:cur_mode)
        return -1
    endif

    if SingleCompileAsync#IsRunning() == 0
        return 1
    endif

    return s:mode_dict['Terminate']()
endfunction

function! SingleCompileAsync#GetOutput() " {{{1
    " get the output of the process.
    " Return -1 if mode hasn't been set;
    " return 1 if a process is running in background;
    " return other integer values if failed to get the output;
    " return a list if the output is successfully gained.

    if empty(s:cur_mode)
        return -1
    endif

    if SingleCompileAsync#IsRunning() == 1
        return 1
    endif

    return s:mode_dict['GetOutput']()
endfunction
" }}}

let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim: fdm=marker et ts=4 tw=78 sw=4 fdc=3
