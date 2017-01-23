"
" Entry point. Map this function to your favourite keys.
"
" autocmd FileType vim nnoremap <buffer><silent> <cr> :call lookup#lookup()<cr>
"
function! lookup#lookup()
  let isk = &iskeyword
  setlocal iskeyword+=:,.,<,>,#,(
  let name = expand('<cword>')
  if name =~ '('
    call s:find_local_func_def(matchstr(name,
          \ '\v\c^%(s:|\<sid\>)\zs.{-}\ze\('))
  elseif name =~ '^s:'
    call s:find_local_var_def(name[2:])
  elseif name =~ '^<sid>'
    call s:find_local_var_def(name[5:])
  elseif stridx(name, '.') > 0
    call search('\c\v^\s*fu%[nction]!?\s+.{-}\.'. name[stridx(name,'.')+1:], 'cesw')
  elseif name =~ '#' && name[0] != '#'
    call s:find_au_def(name)
  endif
  let &iskeyword = isk
endfunction

function! s:find_local_func_def(name)
  call search('\c\v^<fu%[nction]!?\s+%(s:|\<sid\>)\zs\V'. a:name, 'bsw')
endfunction

function! s:find_local_var_def(name)
  call search('\c\v<let\s+s:\zs\V'.a:name.'\s*\=', 'bsw')
endfunction

function! s:find_au_def(name)
  let [path, function] = split(a:name, '.*\zs#')
  let pattern = '\c\v^\s*fu%[nction]!?\s+\V'. path .'#'. function .'\>'
  let name = printf('autoload/%s.vim', substitute(path, '#', '/', 'g'))
  let aufiles = globpath(&runtimepath, name, '', 1)
  if empty(aufiles) && exists('b:git_dir')
    let aufiles = [fnamemodify(b:git_dir, ':h') .'/'. name]
  endif
  if empty(aufiles)
    call search(pattern)
  else
    let aufile = aufiles[0]
    let lnum = match(readfile(aufile), pattern)
    if lnum > -1
      execute 'edit +'. (lnum+1) aufile
    endif
  endif
endfunction
