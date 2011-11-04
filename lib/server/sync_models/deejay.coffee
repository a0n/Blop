_ = require('underscore')._
uuid = require 'node-uuid'
Seq = require 'seq'

DeeJayStore = (key_prefix) ->
  @key_prefix = key_prefix

_.extend(DeeJayStore.prototype, {
 
  findAll: (options) ->
    console.log("starting to find all")
    Seq()
      .seq_((next) ->
        R.keys @key_prefix + "????????-????-????-????-????????????", next
      )
      .flatten()
      .parEach_((next, key) ->
        console.log("key:", key)
        R.hgetall key, next.into(key.replace(/deejay:/, ""))
      )
      .seq_((next, hash) ->
        console.log @vars
        x = _.map @vars, (attributes, id) ->
          console.log(id)
          console.log(attributes)
          
          return _.extend(attributes, {id: id})
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
   
    R.hgetall @key_prefix + ":" + id, (err, response) ->
      if _.isEmpty(response) || err
        options.error("User not found")
      else
        options.success(response)


  save: (model, options) ->
    key_prefix = @key_prefix
    if _.isUndefined(model.id)
      id = uuid()
    else
      id = uuid()
    Seq()
      .seq_((next)->
        if _.isArray model._validate_uniqueness_of 
          next(undefined, model._validate_uniqueness_of)
        else
          next()
      )
      .flatten()
      .parEach_((next, key) ->
        console.log(key)
        R.hget key_prefix + ":" + key + "s", model.get(key), next.into(key)
      )
      .par_((next) ->
        R.exists key_prefix + ":" + id, next.into("id")
      )
      .seq_((next) ->
        if @vars["id"] == 1
          next("STRANGE ERROR - GENERATED UUID IS NOT UNIQUE")
          delete @vars["id"]
        else
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
        console.log "new asdjkkjlasdjkl", model.isNew()
        
        write_transaction = R.multi();
        if model.isNew()
          timestamp = {created_at: Date.now()}
        else
          timestamp = {updated_at: Date.now()}
          
        model.attributes = _.extend(model.attributes, timestamp)
        
        delete @vars["id"]
        
        _.each @vars, (num, key) ->
          write_transaction.hdel key_prefix + ":" + key + "s", model.previous(key) if model.hasChanged(key)
          write_transaction.hsetnx key_prefix + ":" + key + "s", model.get(key), id
        
        if model.hasChanged()
          write_transaction.hmset key_prefix + ":" + id, model.changedAttributes()
        else
          write_transaction.hmset key_prefix + ":" + id, model.toJSON()
        
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
    SS.log.error.message("deejay store destroy")
    if _.isString(model)
     id = model
    else if model
     id = model.id
    
    delete_transaction = R.multi();
    
    delete_transaction.hdel "deejay:emails", model.get("email")
    delete_transaction.hdel "deejay:names", model.get("name")
    delete_transaction.del @key_prefix + id
    delete_transaction.exec (err, replies) ->
      if err || replies == null
        options.error err
      else
        options.success true
})

module.exports = DeeJayStore