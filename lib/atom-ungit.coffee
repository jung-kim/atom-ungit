url = require 'url'
child_process = require 'child_process'
path = require 'path'
http = require 'http'
config = require './atom-ungit-config'
AtomUngitView = require './atom-ungit-view'

isWin = /^win/.test process.platform

# Mac doesn't set PATH env correctly somtimes, and it doesn't hurt to do below
# for linux...
process.env["PATH"] = process.env.PATH + ":/usr/local/bin"  if process.env.PATH.indexOf("/usr/local/bin") < 0  unless isWin

getOptions = (path) ->
  host: "127.0.0.1"
  port: config.port
  path: path
  method: "POST"

module.exports =
  ungitView: null
  ungit: null
  uri: config.uri
  isViewExist: () ->
    panes = atom.workspace.getPanes()
    n = panes.length - 1
    while n > -1
      return panes[n]  if panes[n].getURI == config.uri
      n--
    return

  activate: () ->
    # dependent on tree-view package, which may not be a best idea...
    packages = atom.packages.getActivePackages()
    treeView = undefined
    lastActiveProjectPath = undefined
    n = 0
    while n < packages.length
      if packages[n].name == 'tree-view'
        treeView = packages[n].mainModule.treeView
        n += packages.length
      n++

    getActiveProject = ->
      m = 0
      projectPaths = atom.project.getPaths()
      if treeView
        while m < projectPaths.length
          if treeView.getActivePath()?.startsWith(projectPaths[m])
            return projectPaths[m]
          m++
      if projectPaths then projectPaths[0] else '/'

    atomUngitView = new AtomUngitView(encodeURIComponent(getActiveProject()))

    atom.workspace.onDidChangeActivePaneItem (item) ->
      if item.uri == config.uri
        atomUngitView.loadPath lastActiveProjectPath
      else
        lastActiveProjectPath = getActiveProject()
      return

    atom.commands.add 'atom-workspace',
      'ungit:toggle': =>
        @toggle()
      'ungit:kill': =>
        @kill()

    atom.workspace.addOpener (uriToOpen) ->
      if uriToOpen == config.uri then atomUngitView else undefined

    atom.workspace.onDidOpen (event) ->
      if event.uri == config.uri
        tbs = document.querySelectorAll("ul.tab-bar li.tab div.title")
        i = 0
        while i < tbs.length
          tbs[i].className += " icon icon-ungit"  if tbs[i].textContent is "ungit://ungit-URI"
          i++
      return

  # close atom-ungit page and terminate ungit instance
  kill: ->
    @closeUngit()
    http.request(getOptions("/api/testing/cleanup")).end()
    http.request(getOptions("/api/testing/shutdown")).end()
    return

  closeUngit: ->
    previewPane = atom.workspace.paneForURI(@uri)
    if previewPane
      return previewPane.destroyItem(previewPane.itemForURI(@uri))
    return false;

  # toggle ungit
  #
  # short cut key: ctrl-alt-u
  toggle: ->
    activeItem = atom.workspace.getActivePane().getActiveItem()

    # atom-ungit is in focus, close atom-ungit page but do not terminate ungit process
    if activeItem?.getURI?() is config.uri
      @closeUngit()
      return

    # atom-ungit is not in focus, attempt to start ungit and open atom-ungit
    localUngitExec = 'node ' + path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b --dev --maxNAutoRestartOnCrash=0';
    globalUngitExec = 'ungit --no-b --dev --maxNAutoRestartOnCrash=0';

    if isWin
      execCmd = localUngitExec
    else
      execCmd = 'if [ ! -z "`command -v ungit`" ]; then ' + globalUngitExec + '; else ' + localUngitExec + '; fi'

    # start ungit process in background
    @ungit = child_process.exec(execCmd)
    @ungit.unref()
    self = this

    this.ungit.stdout.on "data", (data) ->
      message = data.toString()

      # when ungit is running...
      if message.indexOf('## Ungit started ##') > -1 || message.indexOf('Ungit server already running') > -1
        atom.workspace.open(config.uri);

      console.log message
      return

    this.ungit.stderr.on "data", (data) ->
      console.error data.toString()
      return
