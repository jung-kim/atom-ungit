module.exports =
  port: 8448
  host: "127.0.0.1"
  getUngitHomeUri: ->
    'http://' + @host + ':' + @port
