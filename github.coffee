
https = require 'https'
jsdom = require 'jsdom'
fs    = require 'fs'
jQ    = fs.readFileSync('jquery-2-0-0.js').toString()
coll  = undefined
status= {}

headers = 
  'User-Agent' : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1502.0 Safari/537.36'
  'Accept'     : 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'

opts  =
  hostname : 'status.github.com'
  method   : 'get'
  port     : 443
  headers  : headers

get = (path, cb) ->
  opts['path'] = path

  https.get opts, (res) ->
    dataBuffer = new Buffer 0
  
    res.on 'data', (data) ->
      dataBuffer = Buffer.concat [dataBuffer, data]
    
    res.on 'end', ->
      jsdom.env
        html: dataBuffer.toString 'utf8'
        src: [jQ]
        done: (errors, window) ->
          cb window.$

handleContent = (path) ->

  get path, ($) ->
    ($ '.message_group').each ->
      date = ($ this).find('h3').text() # date
      
      count = {}
      count['good']  = 0
      count['minor'] = 0
      count['major'] = 0
     
      ($ this).find('.message').each ->
        type = ($ this).attr('class').split(' ')[1]   # type
        time = ($ this).find('.time').text()          # date
        msg  = ($ this).find('.title').text()         # message
        
        count[type]++
        
        dateTime = "#{date} #{time}"
        
        console.log "#{dateTime} #{type} #{msg}"
      
      status[date] = {}
      status[date]['count'] = count  
     
    # previous week 
    prev = ($ 'DIV.pagination > A.prev').attr 'href'
    
    if prev?
      setTimeout ->
        handleContent prev
      , 1
    else
      fs.writeFileSync 'status.json', JSON.stringify status


handleContent '/messages'
