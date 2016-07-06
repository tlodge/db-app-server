require! { crypto, request, './db.ls', './email.ls', './config.json' }

gen-hex = (bytes, callback) !->
  ex, buf <-! crypto.random-bytes bytes
  if ex then throw ex
  callback buf.to-string \hex

encrypt = do
  hash = (string, salt) ->
    sha256 = crypto.create-hash \sha256
    sha256.update salt + string
    salt + sha256.digest \hex

  (string, salt, callback) !->
    if salt
      callback hash string, salt
      return

    hex <-! gen-hex 32bytes
    callback hash string, hex

users = null

handlers =

  #########################################################################

  # TODO: Check email format, name length, and password complexity
  register: (session, data, callback) !->
    unless data.username? and data.password?
      callback error: 11
      return

    err, docs <-! users.find { data.email }
      .to-array!

    if docs.length > 0
      callback error: 12
      return

    err, docs <-! users.find { data.username }
      .to-array!

    if docs.length > 0
      callback error: 13
      return

    # Verify reCAPTCHA
    unless data.recaptcha?
      # No reCAPTCHA
      callback error: 16
      return

    error, response, body <-! request.post do
      url: \https://www.google.com/recaptcha/api/siteverify
      form:
        secret:   config.recaptcha.private-key
        response: data.recaptcha
        remoteip: data.ip

    body = JSON.parse body

    unless body.success
      # reCAPTCHA error
      callback error: 17
      return

    unless not error? and response.status-code is 200
      # Could't verify
      callback error: 17
      return

    password <-! encrypt data.password, null

    rand-hash <-! gen-hex 32bytes

    err <-! users.insert { data.email, data.username, password, unverified: true, rand-hash }
    if err then throw err

    email.verify data.email, data.username, rand-hash

    callback success: true

  #########################################################################

  login: (session, data, callback) !->
    if not data.username or not data.password
      callback error: 11
      return

    err, docs <-! users.find { $or: [ { email: data.username }, { data.username } ] }
      .to-array!

    if docs.length is 0
      callback error: 14
      return

    password <-! encrypt data.password, docs[0].password.slice 0, 64
    if password is not docs[0].password
      callback error: 15
      return

    session.user = docs[0]

    callback success: true

  #########################################################################

  whoami: (session, data, callback) !->
    callback id: session.user?._id

  #########################################################################

  whois: (session, data, callback) !->
    try oid = new db.ObjectID data._id catch then callback error: 31; return

    err, doc <-! users.find-one { $or: [ { _id: oid }, { data.username } ] }

    unless doc?
      callback error: 31
      return

    callback { doc._id, doc.username }

  #########################################################################

  logout: (session, data, callback) !->
    err <-! session.destroy
    if err?
      callback { err }
      return
    callback success: true

  #########################################################################

  verify: (session, data, callback) !->
    if not data.email or not data.hash
      callback redirect: \/
      return

    err, docs <-! users.find { data.email }
      .to-array!

    if docs.length < 1 or not docs[0].rand-hash? or data.hash is not docs[0].rand-hash
      # TODO: Make human-readable
      callback error: 18
      return

    err <-! users.update { _id: docs[0]._id } { $unset: { unverified: '', rand-hash: '' } }
    if err then throw err

    callback redirect: \/

  #########################################################################

export get-handlers = (callback) !-> if users? then callback handlers else db.collection \users !-> users := it; callback handlers
