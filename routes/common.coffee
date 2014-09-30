util = require 'util'
fs = require 'fs'
cheerio = require 'cheerio'
request  = require 'request'
extend = require 'extend'
config = require '../config/config'

# local files list
list = {}

# get an array of objects that match your request for some object properties

Array::where = (query) ->
    return [] if typeof query isnt "object"
    hit = Object.keys(query).length
    @filter (item) ->
        match = 0
        for key, val of query
            match += 1 if item[key] is val
        if match is hit then true else false

exports.index = (req, res, next) ->
  res.render "index",
    list: list

  return

exports.parseHtml = (req, res, next) ->
  url = config.gcmapUrl + req.body.airport
  request url, (error, response, body) ->
    if not error and response.statusCode is 200
      return res.send '400' unless body
      $ = cheerio.load(body)
      obj = 
        name: $('td.fn.org').html()
      $('#mid table.vcard.geo td').each (td) ->
        if $(@).find('abbr').length > 0
          obj.latitude = $(@).text().replace(/<abbr.+<\/abbr>/g, '') if $(@).find('abbr').hasClass('latitude')
          obj.longitude = $(@).text().replace(/<abbr.+<\/abbr>/g, '') if $(@).find('abbr').hasClass('longitude')
          obj.timezone = $(@).text().replace(/<abbr.+<\/abbr>/g, '') if $(@).find('abbr').hasClass('tz')
      list[req.body.airport] = obj
      return res.render "index",
        list: list

exports.getAirport = (req, res, next) ->
  code = req.params.code
  airport = list[code] #(list.where code: code)[0]
  return res.render "airport", 
    opts = 
      code: code
      airport: airport

exports.editAirport = (req, res, next) ->
  code = req.params.code
  list[code] = extend list[code], req.body
  return res.redirect "/"

exports.deleteAirport = (req, res, next) ->
  code = req.params.code
  delete list[code]
  return res.redirect "/"


