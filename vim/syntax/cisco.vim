" Vim syntax file
" Language:             PIX 
" Maintainer:           Tristan ColgateMcFarlane
" Last Change:          March 25, 2008 

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Set the keyword characters
if version < 600
  set isk=@,48-57,_,-
else
  setlocal isk=@,48-57,_,-
endif

" This is a work in process!!!

syn match ciscoComment	"^\!$"
syn match ciscoComment	"^!.*$"
syn match ciscoComment	"^:.*$"

" General definitions
syn keyword ciscoConstantIP any
syn match ciscoConstantIP _\d\{1,3}\.\d\{1,3}\.\d\{1,3}\.\d\{1,3}_
syn match ciscoConstantIP _\d\{1,3}\.\d\{1,3}\.\d\{1,3}\.\d\{1,3}/\d\{1,2}_
syn match ciscoDisabled	"^\s*no .*$"

" Match name statements
syn match ciscoKeyword "^name[s]"
syn match ciscoType "^ name "

" Match interface statements
syn match ciscoDescription "^\sdescription .*"
syn match ciscoKeyword "^spanning-tree"
syn match ciscoType "^ spanning-tree"
syn keyword ciscoKeyword interface
syn keyword ciscoKeyword spanning-tree
syn keyword ciscoType ip
syn keyword ciscoType address
syn keyword ciscoType vrf
syn keyword ciscoType arp
syn keyword ciscoType standby
syn keyword ciscoType switchport
syn keyword ciscoType channel-group
syn keyword ciscoType speed
syn keyword ciscoKeyword snmp-server
syn keyword ciscoKeyword banner
syn match ciscoKeyword "^ip vrf"
syn match ciscoKeyword "^vlan "
syn match ciscoType "^ vlan"

" Match object-group statements
syn keyword ciscoKeyword object-group
syn keyword ciscoType host
syn keyword ciscoType network
syn keyword ciscoKeyword network-object

" Match access-list statements
syn keyword ciscoKeyword access-list
syn keyword ciscoPermit permit
syn keyword ciscoDeny deny
syn keyword ciscoShutdown shutdown

" Match  inspection statements statements
syn keyword ciscoKeyword service-policy
syn keyword ciscoKeyword policy-map
syn keyword ciscoKeyword class-map
syn keyword ciscoKeyword class
syn keyword ciscoKeyword match
syn keyword ciscoKeyword inspect

" System related commands
syn keyword ciscoKeyword ssh
syn keyword ciscoKeyword logging
syn keyword ciscoKeyword tftp-server

" regions
syn region ciscoTextBlock start="\^CC"  end="^\^C"

"
if version >= 508 || !exists("did_cisc_syntax_inits")
  if version < 508
      let did_cisco_syntax_inits = 1
      command -nargs=+ HiLink hi link <args>
   else
      command -nargs=+ HiLink hi def link <args>
  endif

  HiLink ciscoKeyword     Keyword
  HiLink ciscoTodo        Todo
  HiLink ciscoComment     Comment
  HiLink ciscoDisabled    Comment
  HiLink ciscoType        Type
  HiLink ciscoConstantIP  String
  HiLink ciscoSpecial     Special
  HiLink ciscoString      String
  HiLink ciscoDescription String
  HiLink ciscoConditional Conditional
  HiLink ciscoTest        Keyword
  HiLink ciscoPreProc     PreProc
  HiLink ciscoAction      Keyword
  HiLink ciscoPermit      MoreMsg
  HiLink ciscoDeny        WarningMsg
  HiLink ciscoShutdown    WarningMsg
  HiLink ciscoTextBlock   Comment

  delcommand HiLink

endif

let b:current_syntax = "cisco"
