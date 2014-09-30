util = require 'util'
fs = require 'fs'
cheerio = require 'cheerio'
request  = require 'request'
Iconv = require('iconv').Iconv
translator = new Iconv('iso-8859-1','utf-8')
extend = require 'extend'
config = require '../config/config'

# local files list
list = {}

exports.index = (req, res, next) ->
  res.render "index",
    list: list

exports.parseHtml = (req, res, next) ->
  # request body params validation
  #
  req.checkBody('airport', 'Invalid airport code').notEmpty()
  errors = req.validationErrors()
  return res.render "index", { list: list , errors: errors } if errors
  
  url = config.gcmapUrl + req.body.airport
  request {url: url, encoding:  null}, (error, response, body) ->
    if not error and response.statusCode is 200
      # body needs to be converted for utf-8 charset
      #
      body = translator.convert(body).toString()
      $ = cheerio.load(body)

      # select info elements from table
      obj = 
        name: $('td.fn.org').html()
      $('#mid table.vcard.geo td').each (td) ->
        if $(@).find('abbr').length > 0
          obj.latitude = $(@).text().replace(/<abbr.+<\/abbr>/g, '') if $(@).find('abbr').hasClass('latitude')
          obj.longitude = $(@).text().replace(/<abbr.+<\/abbr>/g, '') if $(@).find('abbr').hasClass('longitude')
          obj.timezone = $(@).text().replace(/<abbr.+<\/abbr>/g, '') if $(@).find('abbr').hasClass('tz')
      
      # save data to list
      list[req.body.airport] = obj
      opts = 
        list: list
        errors: null
      return res.render "index", opts

exports.loadAirport = (req, res, next, code) ->
  req.airport = list[code]
  next()

exports.getAirport = (req, res, next) ->
  code = req.params.code
  airport = req.airport # list[code] #(list.where code: code)[0]
  opts = 
      code: code
      airport: airport
      errors: null

  return res.render "airport", opts
    

exports.editAirport = (req, res, next) ->
  code = req.params.code
  airport = req.airport
  
  # request body params validation
  #
  # latitude/longitude: DD°MM'SS"HS (Google Geocoder format), e.g. 50°20'42"N (50.345000) or 176°27'26"W (-176.457221)
  # timezone: UTC (DST), e.g. UTC+2 (DST+3) or UTC+12:45 (DST+13:45)
  #
  req.checkBody('latitude', 'Invalid latitude').matches(/^(\d+°\d+'\d+"\w?)\s\((\W?\d+\.\d+)\)$/i)
  req.checkBody('longitude', 'Invalid longitude').matches(/^(\d+°\d+'\d+"\w?)\s\((\W?\d+\.\d+)\)$/i)
  req.checkBody('timezone', 'Invalid timezone').matches(/^(UTC\W\d+\:?\d*)\s\((DST\W\d+\:?\d*)\)$/i)

  errors = req.validationErrors()
  opts = 
      code: code
      airport: airport
      errors: errors
  return res.render "airport", opts if errors
  
  list[code] = extend req.airport, req.body
  return res.redirect "/"

exports.confirmAirport = (req, res, next) ->
  code = req.params.code
  return res.render "confirm", { code: code }

exports.deleteAirport = (req, res, next) ->
  code = req.params.code
  delete list[code]
  return res.redirect "/"


