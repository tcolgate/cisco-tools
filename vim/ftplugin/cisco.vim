" This functions Adds line numbers to ACLs if they don't
" already have them.
 
:function CiscoNumberACLsFunc() range
:  let CiscoACLs = {}
:  let n = a:firstline
:  while n <= a:lastline 
:    let line = getline(n)
:    if line =~ '^access-list '
:      let linelist = split(line)
:      let aclname = linelist[1]
:      if linelist[2] == 'line'
:        let acllinecnt = str2nr(linelist[4])
:        let CiscoACLs[aclname] = acllinecnt + 1
:      else
:        let acllinecnt = get (CiscoACLs, aclname, 1)
:        call insert(linelist, "line",2)
:        call insert(linelist, acllinecnt,3)
:        call setline(n,join(linelist))
:        let CiscoACLs[aclname] = acllinecnt + 1
:      endif
:    endif
:    let n += 1
:  endwhile
:endfunction

:command -range=% CiscoNumberACLs :<line1>,<line2>call CiscoNumberACLsFunc()

" This function find the location of name and 
" object-group symbols for looking up later
:let g:CiscoSymbolsDict = {}
:function CiscoCollectSymbolsFunc() range
:  let g:CiscoSymbolsDict = {}
:  let n = a:firstline
:  while n <= a:lastline 
:    let line = getline(n)
:    if line =~ '^name '
:      let linelist = split(line)
:      let name = linelist[2]
:      let g:CiscoSymbolsDict[name] = n
:    elseif line =~ '^object-group '
:      let linelist = split(line)
:      let name = linelist[2]
:      let g:CiscoSymbolsDict[name] = n
:    endif
:    let n += 1
:  endwhile
:endfunction
:command -range=% CiscoCollectSymbols :<line1>,<line2>call CiscoCollectSymbolsFunc()

:function CiscoGoToSymbolDef(sym)
:  let lineno = get (g:CiscoSymbolsDict, a:sym,0)
:  if lineno != 0
:    call cursor(lineno,0)
:  endif
:endfunction

:map <F12> :call CiscoGoToSymbolDef("<C-r><C-w>")<CR>
