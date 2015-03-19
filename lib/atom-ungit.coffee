url = require 'url'
child_process = require 'child_process'
path = require 'path'
http = require 'http'
AtomUngitView = require './atom-ungit-view'
config = require './atom-ungit-config'

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
      return panes[n]  if panes[n].itemForUri(config.uri)
      n--
    return

  activate: () ->
    atom.commands.add 'atom-workspace',
      'ungit:toggle': =>
        @toggle()
      'ungit:kill': =>
        @kill()

    atom.workspace.registerOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'ungit:'

      new AtomUngitView()

  # close atom-ungit page and terminate ungit instance
  kill: ->
    @closeUngit()
    http.request(getOptions("/api/testing/cleanup")).end()
    http.request(getOptions("/api/testing/shutdown")).end()
    return

  closeUngit: ->
    previewPane = atom.workspace.paneForUri(@uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForUri(@uri))
      return true;
    return false;

  # toggle ungit
  #
  # short cut key: ctrl-alt-u
  toggle: ->
    activeItem = atom.workspace.getActivePane().getActiveItem()

    # atom-ungit is in focus, close atom-ungit page but do not terminate ungit process
    if activeItem && activeItem.getUri() is config.uri
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
      if message.contains('## Ungit started ##') || message.contains('Ungit server already running')
        paneWithAtomUngit = self.isViewExist()
        # there atom-ungit page is not in focus and focus to atom-ungit page
        if paneWithAtomUngit
          paneWithAtomUngit.activateItemForUri(config.uri)
        else
          # open up atom-ungit page
          item = null
          paneToAddAtomUngit = atom.workspace.getActivePane()
          openers = atom.workspace.openers
          n = openers.length - 1

          while n > -1 and not item
            item = openers[n](config.uri, null)
            n--

          paneToAddAtomUngit.addItem item, 0
          item.loadUngit()  if item instanceof AtomUngitView
          paneToAddAtomUngit.activateItemAtIndex 0

      console.log message
      return

    this.ungit.stderr.on "data", (data) ->
      console.error data.toString()
      return
