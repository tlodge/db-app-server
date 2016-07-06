#!/usr/bin/env lsc

require! {
  express
  'express-session': session
  'body-parser'
  './user.ls'
  './app.ls'
  './config.json'
}

handlers = {}

handlers.user <-! user.get-handlers
handlers.app  <-! app.get-handlers

app = express!

app.enable 'trust proxy'

#err, data <-! fs.read-file 'data/session-cookie-keys.txt', encoding: \utf8

app.use session do
  resave: false
  save-uninitialized: false
  secret: \datashop

app.use body-parser.urlencoded extended: false

#app.use express.static 'static'
app.set \views \views
app.set 'view engine' \jade

app.get \/ (req, res) !->
  unless req.session.user?
    res.render \login
    return

  res.render \dashboard { user: req.session.user }

handle = (req, res, data) !->
  api  = req.params.api
  call = req.params.call
  
  unless api? and call?
    res.write-head 400
    res.end!
    return

  unless api of handlers and call of handlers[api]
    res.write-head 404
    res.end!
    return

  data.ip = req.ip
  out = {} <-! handlers[api][call] req.session, data

  if out.redirect?
    res.redirect out.redirect
    return
  
#do CORS stuff in nginx instead

  res.write-head 200,
#   \Access-Control-Allow-Origin : req.headers.origin or \*
    \Content-Type : \application/json
  res.end JSON.stringify out

app.get  \/:api/:call (req, res) !-> handle req, res, req.query

app.post \/:api/:call (req, res) !-> handle req, res, req.body

app.post '/400' (req, res) !->
  res.write-head 400
  res.end!

app.listen (process.env.PORT or 8080)
