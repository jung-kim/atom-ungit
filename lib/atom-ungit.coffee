url = require 'url'
child_process = require 'child_process'
path = require 'path'
AtomUngitView = require './atom-ungit-view'

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
    ps_result = child_process.exec('ps -ef | grep ungit')
    ps_result.stdout.on 'data', (data) ->
      data.split('\n').map (line) ->
        child_process.exec 'kill ' + line.split(' ')[1]
        console.log 'kill ' + line.split(' ')[1]
        return
    @closeUngit()

  closeUngit: ->
    previewPane = atom.workspace.paneForUri(@uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForUri(@uri))
      return true;
    return false;

  toggle: ->
    if @closeUngit()
      return;

    console.log path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b'

    this.ungit = child_process.exec(path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b')
    # in some cases, $PATH is not sourced with .bashrc, .profile nor .bash_profile
    # I have resolved this issue by establishing a symbolic link but need better solutions.

    # ungit = child_process.exec('echo $PATH')

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
