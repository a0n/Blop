_ = require('underscore')._
Backbone = require('backbone')
rbytes = require("rbytes")

send_response = (err, response, options) ->
  if err
    options.error(err)
  else if _.isUndefined(response)
    options.errror("Reccord not found.")
  else
    options.success(response)

DJStore = (key_prefix) ->
  @key_prefix = "dj:" 

_.extend(DJStore.prototype, {
  findAll: (options) ->
    R.hgetall @key_prefix + id, (err, user) ->
     send_response(err, user, options)

  find: (model, options) ->
    if _.isString(model)
     id = model
    else
     id = model.id
    R.hgetall @key_prefix + id, (err, user) ->
      send_response(err, user, options)
      
  create: (model, options) -> 
    model.id = model.attributes["id"] if model.attributes["id"]
    delete model.attributes["id"]
    if (!model.id)
      model.id = rbytes.randomBytes(16).toHex()
    key_prefix = @key_prefix
    
    
    #Watch key so that after now it won't change anymore until the writetransaction is done
    R.watch(["email:" + model.get("email"), key_prefix + model.id])
    R.exists "email:" + model.get("email"), (err, email_exists) ->
      if email_exists == 1
        send_response("Email does already exist", undefined, options)
      else
        R.exists key_prefix + model.id, (err, id_exists) ->
          if id_exists == 1
            send_response("ID does already exist", undefined, options)
          else
            write_transaction = R.multi();
            timestamp = {created_at: Date.now()}
            model.attributes = _.extend(model.attributes, timestamp)
        
            write_transaction.hmset "email:" + model.get("email"), {id: model.id}
            write_transaction.hmset key_prefix + model.id, model.toJSON()
            write_transaction.exec (err, replies) ->
              if replies == null
                send_response("Object could not be saved. Please try again")
              else
                send_response(err, {}, options)
    
    
  update: (model, options) ->
    if model.changedAttributes()
      timestamp = {updated_at: Date.now()}
      model.attributes = _.extend(model.attributes, timestamp)
      R.hmset @key_prefix + model.id, model.changedAttributes(), (err, response) ->
        send_response(err, {}, options)

  destroy: (model, options) ->
    R.del @key_prefix + model.id, (err, response) ->
      send_response(err, {}, options)
})


DJ = Backbone.Model.extend ({
  initialize: () ->
  
  redisStorage: new DJStore("dj")
    
  # must validate fields in O(1) all calls that need to validate something against the db has to be in the sync method
  validate: (attrs) ->
    console.log("validate with")
    console.log(attrs)
    errors = []
    attributes = _.extend(@attributes, attrs)
    non_allowed_keys = _.difference(_.keys(_.extend(@attributes, attrs)), ["email", "pw", "name", "created_at", "updated_at"])
    if non_allowed_keys.length > 0
      errors.push("The following keys are not allowed: " + non_allowed_keys.join(", "))
    
    if _.isUndefined(attributes["name"])
      errors.push("Name is missing")
    else if attributes["name"].length < 3
      errors.push("This name is to short")
      
    if _.isUndefined(attributes["email"])
      errors.push("Email is missing")
    else if attributes["email"].length < 5
      errors.push("This Email is invalid")
    
    if _.isUndefined(attributes["pw"])
      errors.push("Password is missing")
    else if attributes["pw"].length < 5
      errors.push("This Password is to short")
  
    if _.any(errors)
      return {error: true, message: errors}
    else
      return null
    
  # Needs to be loaded as a Prototype for every Model this is the part that only lies on the server side it provides persitence between server and database
  # on the client siede an extra sync function provides persistence between client and server
  sync: (method, model, options) ->
    resp = undefined
    store = model.redisStorage or model.collection.redisStorage
    console.log("syncing with redis" + method)
    switch method
      when "read"
        if model.id then store.find(model, options) else store.findAll(options)
      when "create"
        store.create(model, options)
      when "update"
        store.update(model, options)
      when "delete"
        store.destroy(model, options)
})

_.extend(SS.models, {dj: DJ})

DJs = Backbone.Collection.extend({
  model: DJ
})

#module.exports = DJ