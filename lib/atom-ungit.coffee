url = require 'url'
child_process = require 'child_process'
path = require 'path'
http = require 'http'
config = require './atom-ungit-config'
AtomUngitView = require './atom-ungit-view'
ps = require 'ps-node'
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
  ungitView: new AtomUngitView()
  activate: () ->
    # dependent on tree-view package, which may not be a best idea...
    packages = atom.packages.getActivePackages()
    treeView = undefined
    self = this
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
            gitRepo = atom.project.getRepositories()[m]
            return if gitRepo then gitRepo.repo.workingDirectory else null
          m++
      if projectPaths then projectPaths[0] else null

    lastActiveProjectPath = getActiveProject()

    atom.workspace.onDidChangeActivePaneItem (item) ->
      if item and item.uri == config.uri
        self.ungitView.loadPath lastActiveProjectPath
      else
        lastActiveProjectPath = getActiveProject()
      return

    atom.commands.add 'atom-workspace',
      'ungit:toggle': =>
        @toggle()
      'ungit:kill': =>
        @kill()

    atom.workspace.addOpener (uriToOpen) ->
      if uriToOpen == config.uri then self.ungitView else undefined

    atom.workspace.onDidOpen (event) ->
      if event and event.uri == config.uri
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
    previewPane = atom.workspace.paneForURI(config.uri)
    if previewPane
      return previewPane.destroyItem(previewPane.itemForURI(config.uri))
    return false

  # toggle ungit
  #
  # short cut key: ctrl-alt-u
  toggle: ->
    activeItem = atom.workspace.getActivePane().getActiveItem()

    # atom-ungit is in focus, close atom-ungit page but do not terminate ungit process
    if activeItem?.uri is config.uri
      @closeUngit()
      return

    # atom-ungit is not in focus, attempt to start ungit and open atom-ungit
    localUngitExec = 'node ' + path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b --dev --maxNAutoRestartOnCrash=0'
    globalUngitExec = 'ungit --no-b --dev --maxNAutoRestartOnCrash=0'

    if isWin
      execCmd = localUngitExec
    else
      execCmd = 'if [ ! -z "`command -v ungit`" ]; then ' + globalUngitExec + '; else ' + localUngitExec + '; fi'

    # start ungit process in background
    ps.lookup({
      command: 'node',
      arguments: 'ungit',
    }, (err, resultList) ->
      console.log err
      console.log resultList
      if err
        console.err "error while process lookup #{ err }"
        throw err;

      if resultList.length < 1
        @ungit = child_process.exec(execCmd)
        @ungit.unref()
        self = this

        this.ungit.stdout.on "data", (data) ->
          message = data.toString()

          # when ungit is running...
          if message.indexOf('## Ungit started ##') > -1 || message.indexOf('Ungit server already running') > -1
            atom.workspace.open(config.uri)

          console.log message
          return

        this.ungit.stderr.on "data", (data) ->
          console.error data.toString()
          return
      else
        atom.workspace.open(config.uri)
    )
