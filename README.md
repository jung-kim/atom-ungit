# ungit package for Atom.io

A project to bring in [ungit](https://github.com/FredrikNoren/ungit) to Atom.io.

Easiest way to work with git in atom.io.

[![Screenshot](https://raw.githubusercontent.com/codingtwinky/atom-ungit/master/screenshot.png)](http://youtu.be/hkBVAi3oKvo)


### Key maps:
* `ctrl-alt-u`: Toggle ungit. If ungit is not running, run ungit and bring up ungit view in atom.io.  If ungit view is in focus, close ungit view but ungit instance will be remained running in background.
* `ctrl-alt-k`: Run terminate ungit. Terminates ungit server instance that was triggered by atom-ungit and closes ungit view in atom.io.  Does not affect ungit instance that was not tirggered via atom-ungit.

### Known issues:
* $PATH environment variable is troublesome for OSX users, see [here](https://github.com/joyent/node/issues/3911).  So starting atom via `atom` command may not work with atom-ungit while starting atom via app icon does.  

  This can be fixed by establishing file links.
  *  Copy the output of `which git`
  *  `ln -fs <<output of previous command>> /usr/bin/git`
  *  Copy the output of `which node`
  *  `ln -fs <<output of previous command>> /usr/bin/node`

### Big thanks to:
* @FredrikNoren
* @ibnesayeed
