''
[include]
  path = .gitconfig.local

[user]
  name = Samuel Leathers
  email = samuel.leathers@iohk.io
  signingkey = 9BCE91C969768E0F

[commit]
  gpgsign = true

[github]
  user = disassembler
[color]
  ui = true

[color "branch"]
  current = yellow reverse
  local = yellow
  remote = green

[color "diff"]
  meta = yellow bold
  frag = magenta bold
  old = red bold
  new = green bold

[alias]
  # add
  a = add                           # add
  chunkyadd = add --patch           # stage commits chunk by chunk

  # branch
  b = branch -v                     # branch (verbose)

  # commit
  c = commit -m                     # commit with message
  ca = commit -am                   # commit all with message
  ci = commit                       # commit
  amend = commit --amend            # ammend your last commit
  ammend = commit --amend           # ammend your last commit

  # checkout
  co = checkout                     # checkout
  nb = checkout -b                  # create and switch to a new branch (mnemonic: "git new branch branchname...")

  # cherry-pick
  cp = cherry-pick -x               # grab a change from a branch

  # diff
  d = diff                          # diff unstaged changes
  dc = diff --cached                # diff staged changes
  last = diff HEAD^                 # diff last committed change

  # log
  l = log --graph --date=short
  changes = log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status
  short = log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"
  changelog = log --pretty=format:\" * %s\"
  shortnocolor = log --pretty=format:\"%h %cr %cn %s\"

  # pull
  pl = pull                         # pull

  # push
  ps = push                         # push

  # rebase
  rc = rebase --continue            # continue rebase
  rs = rebase --skip                # skip rebase

  # remote
  r = remote -v                     # show remotes (verbose)

  # reset
  unstage = reset HEAD              # remove files from index (tracking)
  uncommit = reset --soft HEAD^     # go back before last commit, with files in uncommitted state
  filelog = log -u                  # show changes to a file
  mt = mergetool                    # fire up the merge tool

  # stash
  ss = stash                        # stash changes
  sl = stash list                   # list stashes
  sa = stash apply                  # apply stash (restore changes)
  sd = stash drop                   # drop stashes (destory changes)
  su = stash --include-untracked --keep-index     # stash only what's not in index

  # status
  s = status                        # status
  st = status                       # status
  stat = status                     # status

  # tag
  t = tag -n                        # show tags with <n> lines of each tag message

  # svn helpers
  svnr = svn rebase
  svnd = svn dcommit
  svnl = svn log --oneline --show-commit

[format]
  pretty = format:%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset

[mergetool]
  prompt = false

[merge]
tool = splice

[merge]
  summary = true
  verbosity = 1
  tool = splice

[mergetool "splice"]
  cmd = "vim -f $BASE $LOCAL $REMOTE $MERGED -c 'SpliceInit'"
  trustExitCode = true

[apply]
  whitespace = nowarn

[branch]
  autosetuprebase = always

[push]
  default = tracking

[core]
  autocrlf = false
  editor = vim
  excludesfile = ~/.gitignore

[advice]
  statusHints = false

[diff]
  # Git diff will use (i)ndex, (w)ork tree, (c)ommit and (o)bject
  # instead of a/b/c/d as prefixes for patches
  mnemonicprefix = true
''
