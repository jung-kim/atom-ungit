url = require 'url'
child_process = require 'child_process'
path = require 'path'
AtomUngitView = require './atom-ungit-view'
isWin = /^win/.test process.platform
http = require 'http'
config = require './atom-ungit-config'

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
    result = null
    panes.forEach (pane) ->
      if !result and pane.itemForUri(config.uri)
        result = pane
        return
    result

  activate: () ->
    atom.workspaceView.command 'ungit:toggle', =>
      @toggle()

    atom.workspaceView.command 'ungit:kill', =>
      @kill()

    atom.workspace.registerOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'ungit:'

      new AtomUngitView()

  kill: ->
    http.request(getOptions("/api/testing/cleanup")).end()
    http.request(getOptions("/api/testing/shutdown")).end()
    @closeUngit()
    return

  closeUngit: ->
    previewPane = atom.workspace.paneForUri(@uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForUri(@uri))
      return true;
    return false;

  toggle: ->
    activeItem = atom.workspace.getActivePane().getActiveItem()
    localUngitExec = 'node ' + path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b --dev --maxNAutoRestartOnCrash=0';
    globalUngitExec = 'ungit --no-b --dev --maxNAutoRestartOnCrash=0';

    if activeItem && activeItem.getUri() is config.uri
      @closeUngit()
      return

    if isWin
      @ungit = child_process.exec(localUngitExec)
    else
      @ungit = child_process.exec('if [ ! -z "`command -v ungit`" ]; then ' + globalUngitExec + '; else ' + localUngitExec + '; fi')

    @ungit.unref()
    self = this

    this.ungit.stdout.on "data", (data) ->
      message = data.toString()
      if message.contains('## Ungit started ##') || message.contains('Ungit server already running')
        paneWithAtomUngit = self.isViewExist()
        if paneWithAtomUngit
          paneWithAtomUngit.activateItemForUri(config.uri)
        else
          atom.workspace.open(config.uri).done (ungitView) ->
            if ungitView instanceof AtomUngitView
              ungitView.loadUngit()

      console.log message
      return

    this.ungit.stderr.on "data", (data) ->
      console.log data.toString()
      return
