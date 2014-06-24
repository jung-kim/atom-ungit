url = require 'url'
child_process = require 'child_process'
path = require 'path'
AtomUngitView = require './atom-ungit-view'
isWin = /^win/.test process.platform

module.exports =
  ungitView: null
  ungit: null
  uri: "ungit://ungit-URI"

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
    if isWin
      # possible solutions for windows, need someone with windows machine to test.
      # child_process.exec 'taskkill /IM ungit'
    else
      ps_result = child_process.exec("/bin/ps -ef | grep 'ungit --no-b\|server.js --no-b'")
      ps_result.stdout.on 'data', (data) ->
        data.split('\n').map (line) ->
          child_process.exec 'kill ' + line.split(' ')[1]
          console.log 'kill ' + line.split(' ')[1]
          return
    @closeUngit()
    return

  closeUngit: ->
    previewPane = atom.workspace.paneForUri(@uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForUri(@uri))
      return true;
    return false;

  toggle: ->
    if @closeUngit()
      return;

    if isWin
      # Not sure if below code sthill works for windows, but it may.  In such cases there is no reason for this distinctions.
      # this.ungit = child_process.exec(path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b')
    else
      this.ungit = child_process.exec(path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b')

    started = false

    this.ungit.unref();
    uri = @uri;
    this.ungit.stdout.on "data", (data) ->
      message = data.toString();
      if !started && (message.contains('## Ungit started ##') || message.contains('Ungit server already running'))
        started = true
        previousActivePane = atom.workspace.getActivePane()
        atom.workspace.open(uri, searchAllPanes: true).done (ungitView) ->
          if ungitView instanceof AtomUngitView
            ungitView.loadUngit()
            previousActivePane.activate()
      console.log message
      return

    this.ungit.stderr.on "data", (data) ->
      console.log data.toString()
      return
