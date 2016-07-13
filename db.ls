require! mongodb

_db = null

connect = (callback) !->
  err, db <-! mongodb.MongoClient.connect 'mongodb://mongo:27017/datashop'
  if err then throw err
  _db := db
  callback db

export mongodb.ObjectID
export collection = (name, callback) !-> if _db? then name |> _db.collection |> callback else connect !-> name |> it.collection |> callback
