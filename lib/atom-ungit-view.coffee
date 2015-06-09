# from https://github.com/gabceb/atom-web-view.
# For some reason APM won't let me download the package

{$, ScrollView} = require 'atom-space-pen-views'

# View that renders the image of an {WebEditor}.
module.exports =
class AtomUngitView extends ScrollView

  @content: ->
    @div class: 'web-view-area', =>
      @iframe id: 'web-view-iframe', name: 'disable-x-frame-options', tabindex: -1, src: "", width: "100%", height: "100%", frameBorder: "0"

  constructor: (uri) ->
    super
    @.find('#web-view-iframe').attr('src', uri)

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
