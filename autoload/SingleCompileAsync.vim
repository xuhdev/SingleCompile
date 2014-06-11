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

" File: autoload/SingleCompileAsync.vim
" Version: 2.12.0
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

    let l:ret = ''

python << EEOOFF

try:
    import vim
    import shlex
    import subprocess
    import sys
except:
    vim.command("let l:ret = 'Library import error.'")
EEOOFF

    if !empty(l:ret)
        return l:ret
    endif

python << EEOOFF
if sys.version_info[0] < 2 or sys.version_info[1] < 6:
    vim.command("let l:ret = 'At least python 2.6 is required.'")
EEOOFF

    if !empty(l:ret)
        return l:ret
    endif

python << EEOOFF

class SingleCompileAsync:
    sub_proc = None
    output = None
    # This value will be set below if we are on win32. For other systems,
    # leave this as None
    startupinfo = None

# if we are on win32, we need to set STARTUPINFO before calling
# subprocess.Popen() to make the console of the subprocess show minimized and
# not actived.
if sys.platform == 'win32':

    # set subprocess constants
    subprocess.STARTF_USESHOWWINDOW = 1
    subprocess.SW_HIDE = 0

    SingleCompileAsync.startupinfo = subprocess.STARTUPINFO()
    SingleCompileAsync.startupinfo.dwFlags = subprocess.STARTF_USESHOWWINDOW
    SingleCompileAsync.startupinfo.wShowWindow = subprocess.SW_HIDE

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
    SingleCompileAsync.sub_proc = subprocess.Popen(
            shlex.split(vim.eval('a:run_command')),
            shell = False,
            universal_newlines = True,
            startupinfo = SingleCompileAsync.startupinfo,
            stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

except:
    vim.command('let l:ret_val = 2')

EEOOFF

    return l:ret_val
endfunction

function! s:TerminatePython() " {{{2
    " The Terminate function of python

    let l:ret_val = 0

python << EEOOFF

try:
    SingleCompileAsync.sub_proc.kill()
except:
    vim.command('let l:ret_val = 2')

EEOOFF

    return l:ret_val
endfunction

function! s:GetOutputPython() " {{{2
    " The GetOutput function of python

python << EEOOFF
try:
    SingleCompileAsync.tmpout = SingleCompileAsync.sub_proc.communicate()[0]
except:
    pass
else:
    SingleCompileAsync.output = SingleCompileAsync.tmpout
    del SingleCompileAsync.tmpout

try:
    vim.command("let l:ret_val = '" +
            SingleCompileAsync.output.replace("'", "''") + "'")
except:
    vim.command('let l:ret_val = 2')

EEOOFF

    if type(l:ret_val) == type('')
        let l:ret_list = split(l:ret_val, "\n")
        unlet! l:ret_val
        let l:ret_val = l:ret_list
    endif

    return l:ret_val
endfunction

function! SingleCompileAsync#GetMode() " {{{1
    return s:cur_mode
endfunction

function! SingleCompileAsync#Initialize(mode) " {{{1
    " return 1 if failed to initialize the mode;
    " return 2 if mode has been set;
    " return 3 if the specific mode doesn't exist;
    " return 0 if succeed.

    " only set to the new mode if no mode is set before.
    if !empty(s:cur_mode)
        return 2
    endif

    " set function refs to dict
    if a:mode ==? 'auto'
        " autodetect for an appropriate mode

        for l:one_mode in ['python']

            let l:init_result = SingleCompileAsync#Initialize(l:one_mode)
            if type(l:init_result) == type(0) && l:init_result == 0
                return 0
            endif
        endfor

        return 0

    elseif a:mode ==? 'python'
        let s:mode_dict['Initialize'] = function('s:InitializePython')
        let s:mode_dict['IsRunning'] = function('s:IsRunningPython')
        let s:mode_dict['Run'] = function('s:RunPython')
        let s:mode_dict['Terminate'] = function('s:TerminatePython')
        let s:mode_dict['GetOutput'] = function('s:GetOutputPython')
    else
        return 3
    endif

    " call the initialization function
    let l:init_result = s:mode_dict['Initialize']()

    if type(l:init_result) == type('') ||
                \ (type(l:init_result) == type(0) && l:init_result != 0)
        return l:init_result
    endif

    let s:cur_mode = a:mode

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

" vim703: cc=78
" vim: fdm=marker et ts=4 tw=78 sw=4 fdc=3
