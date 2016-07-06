require! [ './db.ls' ]


apps = null

handlers =

  #########################################################################

  # TODO: Limit info length and further validate input
  post: (session, data, callback) !->
    #unless session.user?
    #  callback error: 22
    #  return

    # TODO: Only let verified users post
    # TODO: Consider marking all apps hidden to public by default (or warning)

    # TODO: Validate manifest!

    manifest = JSON.parse data?.manifest
    entry =
      manifest: manifest
      poster:
        id:       'tlodge'
        username: 'tlodge'
      post-date: new Date!
      queries: 0
	
    #entry =
    #  manifest: manifest
    #  poster:
    #    id:       session.user._id
    #    username: session.user.username
    #  post-date: new Date!
    #  queries: 0

    unless entry.manifest?
      callback error: 21
      return

    # TODO: Copy needed values from data; this is dangerous
    # TODO: Check that version is further on upsert and validate
    err <-! apps.update 'manifest.name': manifest.name, entry, upsert: true
    if err then throw err

    callback success: true

  #########################################################################

  list: (session, data, callback) !->
    
    err, docs <-! apps.find!.sort $natural: 1 .to-array!
    if err then throw err

    callback apps: docs

  #########################################################################

  get: (session, data, callback) !->
    console.log "---------------"
    console.log "seen an app get "
    console.log data
    err, doc <-! apps.find-one 'manifest.name': data.name
    if err then throw err

    unless doc?
      callback error: 23
      return

    callback doc

  #########################################################################

export get-handlers = (callback) !-> if apps? then callback handlers else db.collection \apps !-> apps := it; callback handlers
