"
" Entry point. Map this function to your favourite keys.
"
" autocmd FileType vim nnoremap <buffer><silent> <cr> :call lookup#lookup()<cr>
"
function! lookup#lookup()
  let isk = &iskeyword
  setlocal iskeyword+=:,.,<,>,#
  let name = expand('<cword>')
  if name =~# '^s:'
    call s:find_local_definition(name[2:])
  elseif name =~ '^<sid>'
    call s:find_local_definition(name[5:])
  elseif stridx(name, '.') > 0
    call search('\c\v^\s*fu%[nction]!?\s+.{-}\.'. name[stridx(name,'.')+1:], 'cesw')
  elseif name =~ '#' && name[0] != '#'
    call s:find_autoload_definition(name)
  endif
  let &iskeyword = isk
endfunction

"
" Jump to a script-local definition:
"
"    s:var
"    s:func()
"    <sid>var
"    <sid>func()
"
function! s:find_local_definition(name)
  if !search('\c\v^\s*fu%[nction]!?\s+%(s:|\<sid\>)\zs\V'. a:name, 'bsw')
    call search('\c\vlet\s+%(s:|\<sid\>)\zs\V'.a:name.'\s*\=', 'bsw')
  endif
endfunction

"
" Jump to autoload definition autoload#func().
"
function! s:find_autoload_definition(name)
  let [path, function] = split(a:name, '.*\zs#')
  let pattern = '\c\v^\s*fu%[nction]!?\s+\V'. path .'#'. function .'\>'
  let name = printf('autoload/%s.vim', substitute(path, '#', '/', 'g'))
  let autofiles = globpath(&runtimepath, name, '', 1)
  if empty(autofiles) && exists('b:git_dir')
    let autofiles = [fnamemodify(b:git_dir, ':h') .'/'. name]
  endif
  if empty(autofiles)
    call search(pattern)
  else
    let autofile = autofiles[0]
    let lnum = match(readfile(autofile), pattern)
    if lnum > -1
      execute 'edit +'. (lnum+1) autofile
    endif
  endif
endfunction