if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin=1

"Disable interactive feature
"let g:fstar_inter = 1

"Disable mappings
"let g:fstar_inter_maps = 1

fu! Ffind_fstar()
  " convert the system path to a comma-separated list of directories
  " suitable for globpath() consumption.
  " 
  " first, commas must be escaped with a backslash.
  " todo: test a path with a comma in it to make sure this works.
  let l:jpath = substitute($PATH,",","\\,","g")
  " different platforms use different path separators.
  if has('win32')
     " additionally, Windows paths need to have trailing backslashes removed.
     let l:jpath = substitute(l:jpath,"\\;",";","g")
     let l:jpath = substitute(l:jpath,";",",","g")
  else
     let l:jpath = substitute(l:jpath,":",",","g")
  endif
  " todo: ask regarding why newlines would be in $PATH?
  let l:jpath = substitute(l:jpath,"\n","","g")
" Decho("[Ffind_fstar] l:jpath=" . l:jpath)

  let l:matchs = globpath(l:jpath,"fstar.exe")
" Decho("[Ffind_fstar] l:matchs=" . l:matchs)
  return l:matchs
endfunction

if exists("g:vimfstar_fstar_exe_path")
  let exe_path = fnamemodify(g:vimfstar_fstar_exe_path, ':p')
else
  let exe_path = fnamemodify(Ffind_fstar(), ':p')
endif
if executable(exe_path)
  let g:vimfstar_fstar_exe_path = exe_path
  echom "Using F* from `" . exe_path . "`."
else
  echoerr "The path specified by `g:vimfstar_fstar_exe_path` does not point to an executable nor can `fstar.exe` be found in the PATH. Please verify that one of these options is available to VimFStar."
endif

let s:matchs = g:vimfstar_fstar_exe_path
if !empty(s:matchs) && !exists('g:fstar_inter')
  let g:fstar_inter = 1

  py import sys
  py import os.path
  py import vim
  py sys.argv = [ os.path.normcase(os.path.normpath(os.path.join(vim.eval('expand("<sfile>:p:h")'), '../plugin/VimFStar/start.py'))) ]
  py sys.path.insert(0, os.path.dirname(sys.argv[0]))
  pyfile <sfile>:p:h/../plugin/VimFStar/start.py

  fu! s:import_python_function(fn_name, arg_names)
     let l:viml_name = "s:" . a:fn_name
     let l:body = "fu! " . l:viml_name . "(" . join(a:arg_names, ",") . ")\n"
     let l:body .= "   let l:pycall = '" . a:fn_name . "'\n"
     let l:body .= "   py plugin.vimcall()\n"
     let l:body .= "   return l:pyresult\n"
     let l:body .= "endfunction"
     execute l:body
  endfunction

  call s:import_python_function('start', [])
  call s:import_python_function('stop', ['force'])
  call s:import_python_function('refresh', [])
  call s:import_python_function('find_exe_path', ['filespec'])
  call s:import_python_function('set_exe_path', ['path'])
  call s:import_python_function('get_exe_path', [])

  au VimLeave * call s:stop(1)

  "call s:set_exe_path('C:\Users\mirobert\Documents\wip\Echo\Echo\bin\Debug\Echo.exe')
  call s:set_exe_path(g:vimfstar_fstar_exe_path)
  call s:start()

  fu! Ftest_code ()
    py fstar_vim_test_code()
  endfunction

  fu! Funtil_cursor()
    py fstar_vim_until_cursor()
  endfunction

  fu! Funtil_cursor_quick()
    py fstar_vim_until_cursor(True)
  endfunction

  fu! Fget_result()
    py fstar_vim_query_answer()
  endfunction

  fu! Freset()
    py fstar_reset()
  endfunction

  fu! Fget_answer()
    py fstar_vim_get_answer()
  endfunction

  "py fstar_init()

  command Funtil call Funtil_cursor()
  command Funtilquick call Funtil_cursor_quick()
  command Fresult call Fget_result()
  command Freset call Freset()
  command Fanswer call Fget_answer()

  "Here you can set the color you want for checked code
  highlight FChecked ctermbg=darkgrey guibg=lightGreen
endif

if !exists("g:fstar_inter_maps")
  vnoremap <buffer> <F2> :<C-u>call Ftest_code()<CR>
  nnoremap <buffer> <F2> :call Funtil_cursor()<CR>
  nnoremap <buffer> <F3> :call Fget_result()<CR>
  nnoremap <buffer> <F4> :call Fget_answer()<CR>
  nnoremap <buffer> <F5> (v)k$<CR>
  nnoremap <buffer> <F6> :call Funtil_cursor_quick()<CR>
  "<C-u> is to remove '<,'> which execute the command for each selected line
endif

" Add mappings, unless the user didn't want this.
if !exists("no_plugin_maps") && !exists("no_fstar_maps")
  " (un)commenting
  if !hasmapto('<Plug>Comment')
    nmap <buffer> <LocalLeader>c <Plug>LUncomOn
    xmap <buffer> <LocalLeader>c <Plug>BUncomOn
    nmap <buffer> <LocalLeader>C <Plug>LUncomOff
    xmap <buffer> <LocalLeader>C <Plug>BUncomOff
  endif

  nnoremap <buffer> <Plug>LUncomOn gI(* <End> *)<ESC>
  nnoremap <buffer> <Plug>LUncomOff :s/^(\* \(.*\) \*)/\1/<CR>:noh<CR>
  xnoremap <buffer> <Plug>BUncomOn <ESC>:'<,'><CR>`<O<ESC>0i(*<ESC>`>o<ESC>0i*)<ESC>`<
  xnoremap <buffer> <Plug>BUncomOff <ESC>:'<,'><CR>`<dd`>dd`<
endif

" vim:set sts=2 sw=2 et ft=vim:
