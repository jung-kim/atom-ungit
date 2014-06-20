url = require 'url'
child_process = require 'child_process'
path = require 'path'
AtomUngitView = require './atom-ungit-view'

module.exports =
  ungitView: null
  ungit: null

  activate: (state) ->
    atom.workspaceView.command 'ungit:toggle', =>
      @toggle()

    atom.workspace.registerOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'ungit:'

      new AtomUngitView()

  toggle: ->
    uri = "ungit://ungit-URI"

    previewPane = atom.workspace.paneForUri(uri)
    if previewPane
      this.ungit.kill()
      previewPane.destroyItem(previewPane.itemForUri(uri))
      return

    console.log path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b'

    this.ungit = child_process.exec(path.join(__dirname, '../node_modules/ungit/bin/ungit') + ' --no-b')
    # in some cases, $PATH is not sourced with .bashrc, .profile nor .bash_profile
    # I have resolved this issue by establishing a symbolic link but need better solutions.

    # ungit = child_process.exec('echo $PATH')

    started = false

    this.ungit.unref();
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
