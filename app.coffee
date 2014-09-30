
###
Module dependencies.
###
express = require("express")
common = require("./routes/common")
fs = require("fs")
http = require("http")
util = require("util")
path = require("path")
app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.set "views", path.join(__dirname, "views")
app.set "view engine", "jade"
app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser(
  keepExtensions: true
  uploadDir: __dirname + "/public/images"
)
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router
app.use require("stylus").middleware(path.join(__dirname, "public"))
app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")
app.get "/", common.index
app.post "/", common.parseHtml
#CRUD
app.get "/airport/:code", common.getAirport
app.post "/airport/:code", common.editAirport
app.get "/airport/delete/:code", common.deleteAirport

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
  return
