_ = require('underscore')._
Backbone = require 'backbone'
rbytes = require 'rbytes'
Seq = require 'seq'

callRedis = (command, key, value, success) ->
  handle_response = (err, response) ->
    if err
      throw new Error(err)
    else if command == ("exists"||"hexists")
      success(response == 1 ? true : false)
    else 
      success response
  
  options = {}
  
  if _.isString(command)
    if _.isUndefined(R[command])
      throw new Error("redis command not found")
  else
    throw new Error("wrong command")
    
  unless _.isString(key)
    throw new Error("wrong key")
    
  if _.isFunction(value)
    if _.isUndefined(success)
      success = value
    value = undefined
    
  if _.isEmpty(value)
    R[command] key, handle_response
  else
    R[command] key, value, handle_response

DJStore = (key_prefix) ->
  @key_prefix = "dj:" 

_.extend(DJStore.prototype, {
    
  findAll: (options) ->
    R.hgetall @key_prefix + id, (err, user) ->
     options.success(user)

  find: (model, options) ->
    if _.isString(model)
     id = model
    else if model
     id = model.id
    
    callRedis "hgetall", @key_prefix + id, options.error, (dj_hash) ->
      if _.isEmpty(dj_hash)
        options.error("User not found")
      else
        options.success(dj_hash)
  
  create: (model, options) ->
    key_prefix = @key_prefix
    model.id = rbytes.randomBytes(16).toHex()
    Seq()
      .par_((next) -> R.exists key_prefix + model.id, next)
      .par_((next) -> R.hexists "dj:emails", model.get("email"), next)
      .par_((next) -> R.hexists "dj:names", model.get("name") , next)
      .seq_((next, key_exists, email_exists, name_exists) ->
        console.log(key_exists, email_exists, name_exists)
        if (key_exists)
          options.error("key exists")
        else if (email_exists)
          options.error("email exists")
        else if (name_exists)
          options.error("name exists")
        else
          next()
      )
      .seq_((next) ->
        write_transaction = R.multi();
        timestamp = {created_at: Date.now()}
        model.attributes = _.extend(model.attributes, timestamp)

        write_transaction.hsetnx "dj:emails", model.get("email"), model.id
        write_transaction.hsetnx "dj:names", model.get("name"), model.id

        write_transaction.hmset key_prefix + model.id, model.toJSON()
        write_transaction.exec (err, replies) ->
          if replies == null || err
            options.error("Object could not be saved. Please try again")
          else
            options.success(timestamp)
      )
    return undefined
    
  update: (model, options) ->
    # we need to prevent that the user changes the email to his account, maybe it is better ONLY use emails - and don't use any id's for the user - but i guess that it would
    # be nicer to support multiple emails and accounts for authentication bringing a little more complexity
    if model.changedAttributes()
      timestamp = {updated_at: Date.now()}
      model.attributes = _.extend(model.attributes, timestamp)
      R.hmset 
      R.hmset @key_prefix + model.id, model.changedAttributes(), (err, response) ->
        if err
          options.error err
        else
          options.success timestamp

  destroy: (model, options) ->
    R.del, @key_prefix + model.id, (err, response) ->
      if err
        options.error err
      else
        options.success true
})


DJ = Backbone.Model.extend ({
  initialize: () ->
  
  redisStorage: new DJStore("dj")
    
  # must validate fields in O(1) all calls that need to validate something against the db has to be in the sync method
  validate: (attrs) ->
    console.log("validate with", attrs)
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
      console.log("VALIDATION ERROR!")
      return {error: true, message: errors}
    else
      return null
    
  # Needs to be loaded as a Prototype for every Model this is the part that only lies on the server side it provides persitence between server and database
  # on the client siede an extra sync function provides persistence between client and server
  sync: (method, model, options) ->
    resp = undefined
    store = model.redisStorage or model.collection.redisStorage
    console.log("Syncing with redis calling method: " + method)
    try
      switch method
        when "read"
          if model.id then store.find(model, options) else store.findAll(options)
        when "create"
          store.create(model, options)
        when "update"
          store.update(model, options)
        when "delete"
          store.destroy(model, options)
    catch error
      console.log("Cathing Error in Backbone.sync", error)
      options.error(error)
})

_.extend(SS.models, {dj: DJ})

DJs = Backbone.Collection.extend({
  model: DJ
})

#module.exports = DJ