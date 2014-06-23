{$, $$$, ScrollView} = require 'atom'

module.exports =
class AtomUngitView extends ScrollView
  atom.deserializers.add(this)

  @content: ->
    @div class: 'atom-ungit native-key-bindings', tabindex: -1

  destroy: ->
    @unsubscribe()

  loadUngit: ->
    @showLoading()
    @setTabLogo()
    @createIframe()

  setTabLogo: ->
    tbs = document.querySelectorAll("ul.tab-bar li.tab div.title")
    i = 0
    while i < tbs.length
      tbs[i].className += " atom-ungit-tab"  if tbs[i].textContent is "Ungit"
      i++

  createIframe: ->
    iframe = document.createElement("iframe")
    iframe.sandbox="allow-same-origin allow-scripts"
    iframe.src = @getRepoUri()

    @html $ iframe

  getRepoUri: ->
    uri = "http://127.0.0.1:8448"
    if atom.project.getRootDirectory()
      uri += "/#/repository?path=" + atom.project.getRootDirectory().path
    uri

  getTitle: ->
    "Ungit"

  getUri: ->
    "ungit://ungit-URI"

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Loading Ungit Failed!'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @html $$$ ->
      @div class: 'atom-html-spinner', 'Loading Ungit\u2026'
