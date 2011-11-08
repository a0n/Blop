_ = require('underscore')._
uuid = require 'node-uuid'
Seq = require 'seq'

owl = SS.require("sync_models/pluralize.js")

ObjectStore = (options) ->
  @model_name = options.model_name
  @collection_name = options.collection_name
  @key_prefix = options.model_name + ":"

_.extend(ObjectStore.prototype, {
 
  findAll: (collection, options) ->
    key_prefix = @key_prefix
    model_name = @model_name
    collection_name = @collection_name
    
    console.log("starting to find all")
    console.log(collection)
    console.log(collection_name)
    console.log(collection.parrent)
    if _.isUndefined(collection.parrent)
      console.log("getting all djs")
      Seq()
        .seq_((next) ->
          R.hgetall key_prefix + "ids", next
        )
        .seq_((next, hash) ->
          x = _.map hash, (attributes, id) ->
            return _.extend(JSON.parse(attributes), {id: id})
          options.success x if _.isFunction(options.success)
        )
        .catch((err) ->
          if options.error
            options.error err
          else
            SS.log.error.message(err)
        )
    else if _.isString(collection_name) && _.isString(collection.parrent.id)
      console.log("getting collection for model")
      collection_key = key_prefix + collection.parrent.id + ":" + collection_name
      Seq()
        .seq_((next) ->
          R.smembers collection_key, next
        )
        .flatten()
        .parEach_((next, id) ->
          R.hget key_prefix + "ids", id, next.into(id)
        )
        .seq_((next) ->
          console.log("VARS")
          console.log(@vars)
          x = _.map @vars, (attributes, id) ->
            if _.isString(attributes) && _.isString(id) 
              return _.extend(JSON.parse(attributes), {id: id})
          options.success x if _.isFunction(options.success)
        )
        .catch((err) ->
          if options.error
            options.error err
          else
            SS.log.error.message(err)
        )    
    
    return undefined

  find: (model, options) ->
    if _.isString(model)
     id = model
    else if model
     id = model.id
   
    key_prefix = @key_prefix
   
    R.hget key_prefix + "ids", id, (err, response) ->
      response = JSON.parse(response)
      if err
        SS.log.error.message(err)
        options.error(err)
      else if _.isEmpty(response)
        SS.log.error.message("User not found")
        options.error("User not found")
      else
        options.success(response)


  save: (model, options) ->
    key_prefix = @key_prefix
    if _.isUndefined(model.id)
      id = uuid()
    else
      id = model.id
    
    if model.hasChanged()
      unique_keys = _.intersection( _.keys(model.changedAttributes()), model._unique_index_of) 
    else
      unique_keys = model._unique_index_of
      
    Seq()
      .seq_((next) ->
        R.watch key_prefix + "ids", next
      )
      .seq_((next)->
        R.hexists key_prefix + "ids", id, next
      )
      .seq_((next, id_existence) ->
        if model.isNew() && id_existence == 1
          next("The id for this new model is already in use!")
        else if model.hasChanged() && id_existence == 0
          next("The id for this new model is not in the database!")
        else
          next(undefined, unique_keys)
      )
      .flatten()
      .parEach_((next, key) ->
        console.log("watching")
        R.watch key_prefix + owl.pluralize(key), next
      )
      .seq_((next) ->
        next(undefined, unique_keys)
      )
      .flatten()
      .parEach_((next, key) ->
        console.log(key)
        R.hget key_prefix + owl.pluralize(key), model.get(key), next.into(key)
      )
      .seq_((next) ->
        console.log "fck"
        console.log @vars
        existing_keys = []
        _.each @vars, (val, key) ->
          if _.isString(val) && val != id
            existing_keys.push key
        if existing_keys.length == 0
          next()
        else
          next("The following keys are not unique: " + existing_keys.join(", "))
      )
      .seq_((next) ->
        write_transaction = R.multi();
        if model.isNew()
          timestamp = {created_at: Date.now()}
        else
          timestamp = {updated_at: Date.now()}
          
        model.attributes = _.extend(model.attributes, timestamp)
        
        _.each @vars, (num, key) ->
          write_transaction.hdel key_prefix + owl.pluralize(key), model.previous(key) if model.hasChanged(key)
          write_transaction.hsetnx key_prefix + owl.pluralize(key), model.get(key), id
        
        if model.hasChanged()
          write_transaction.hset key_prefix + "ids", id, JSON.stringify(model.changedAttributes())
        else
          write_transaction.hsetnx key_prefix + "ids", id, JSON.stringify(model.toJSON())
        
        write_transaction.exec (err, replies) ->
          console.log("replies", replies)
          if replies == null || err
            next("Object could not be saved. Please try again")
          else
            if err
              options.error("User not found")
            else
              if model.id
                options.success(timestamp)
              else
                options.success(_.extend(timestamp, {id: id}))
      )
      .catch((err) ->
        if options.error
          SS.log.error.message(err)
          options.error err
        else
          SS.log.error.message(err)
      )

    return undefined

  create: (model, options) ->
    @.save(model, options)
    
  update: (model, options) ->
    @.save(model, options)

  destroy: (model, options) ->
    if _.isString(model)
     id = model
    else if model
     id = model.id
    
    key_prefix = @key_prefix
    
    delete_transaction = R.multi();
    
    _.each model._unique_index_of, (key) ->
      delete_transaction.hdel key_prefix + owl.pluralize(key), id
    delete_transaction.hdel key_prefix + "ids", id
    delete_transaction.exec (err, replies) ->
      if err || replies == null
        SS.log.error.message(err)
        options.error err
      else
        options.success true
})

module.exports = ObjectStore