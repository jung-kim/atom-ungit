# ungit package for Atom.io

A project to bring in [ungit](https://github.com/FredrikNoren/ungit) to Atom.io.

Easiest way to work with git in atom.io.

[![Screenshot](https://raw.githubusercontent.com/codingtwinky/atom-ungit/master/screenshot.png)](http://youtu.be/hkBVAi3oKvo)


###Key maps:
* `ctrl-alt-u`: If ungit is open and not focused, bring ungit to focus.  If ungit is open and focused, close ungit tab.  If ungit is not opened, start ungit and redirect to ungit.
* `ctrl-alt-k`: Run terminate ungit. Terminates ungit server instance that was opened by atom.io

###Known issues:
* $PATH environment variable is troublesome for OSX users, see [here](https://github.com/joyent/node/issues/3911).  So starting atom via `atom` command may not work while starting atom via app icon does.  This can be fixed by establishing file links.
  *  Copy the output of `which git`
  *  `ln -fs <<output of previous command>> /usr/bin/git`
  *  Copy the output of `which node`
  *  `ln -fs <<output of previous command>> /usr/bin/node`

###Big thanks to:
* @FredrikNoren
* @ibnesayeed
