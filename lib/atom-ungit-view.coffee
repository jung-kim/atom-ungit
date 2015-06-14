# from https://github.com/gabceb/atom-web-view.
# For some reason APM won't let me download the package

config = require './atom-ungit-config'
{$, ScrollView} = require 'atom-space-pen-views'

# View that renders the image of an {WebEditor}.
module.exports =
class AtomUngitView extends ScrollView

  @content: ->
    @div class: 'web-view-area atom-ungit', =>
      @iframe id: 'web-view-iframe', name: 'disable-x-frame-options'

  constructor: () ->
    super
    @uri = config.uri

  @deserialize: ({uri}) ->

  # Gets the title of the page based on the uri
  #
  # Returns a {String}
  getTitle: ->
    @uri || 'Uri-web'

  # Serializes this view
  #
  serialize: ->
    {@uri, deserializer: @constructor.name}

  # Retrieves this view's pane.
  #
  # Returns a {Pane}.
  getPane: ->
    @parents('.pane').view()

  getURI: ->
    @uri

  loadPath: (path) ->
    if @path != path
      @path = path
      src = config.getUngitHomeUri()
      if path
        src += '/?noheader=true#/repository?path=' + encodeURIComponent(path)
      @find('#web-view-iframe').attr 'src', src
