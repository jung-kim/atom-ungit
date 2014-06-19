{$, $$$, ScrollView} = require 'atom'

module.exports =
class AtomUngitView extends ScrollView
  atom.deserializers.add(this)

  @content: ->
    @div class: 'atom-html-preview native-key-bindings', tabindex: -1

  destroy: ->
    @unsubscribe()

  renderHTML: ->
    @showLoading()
    @renderHTMLCode()

  renderHTMLCode: () ->
    text = """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>HTML Preview</title>
        <style>
          body {
            font-family: "Helvetica Neue", Helvetica, sans-serif;
            font-size: 14px;
            line-height: 1.6;
            background-color: #fff;
            overflow: scroll;
            box-sizing: border-box;
          }
        </style>
      </head>
      <body>

      </body>
    </html>
    """
    iframe = document.createElement("iframe")
    iframe.src = "http://127.0.0.1:8448"
    iframe.sandbox="allow-same-origin allow-scripts"
    iframe.width = "100%"
    iframe.height = "100%"

    @html $ iframe
    @trigger('atom-html-preview:html-changed')

  getTitle: ->
    "Ungit"

  getUri: ->
    "ungit://ungit-URI"

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing HTML Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @html $$$ ->
      @div class: 'atom-html-spinner', 'Loading HTML Preview\u2026'
