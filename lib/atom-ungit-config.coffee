fs = require("fs")
path = require("path")
home = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
file = path.join(home, '.ungitrc');

if fs.existsSync(file)
  data = JSON.parse(fs.readFileSync(file, "utf8"))
else
  data = {}

module.exports =
  port: data.port or 8448
  host: data.host or '127.0.0.1'
  getUngitHomeUri: ->
    'http://' + @host + ':' + @port
  uri: 'ungit://ungit-URI'
