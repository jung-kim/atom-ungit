url = require 'url'

AtomUngitView = require './atom-ungit-view'

module.exports =
  ungitView: null

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
      previewPane.destroyItem(previewPane.itemForUri(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, searchAllPanes: true).done (ungitView) ->
      if ungitView instanceof UngitView
        ungitView.renderHTML()
        previousActivePane.activate()
