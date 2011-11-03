_ = require('underscore')._
uuid = require 'node-uuid'
Seq = require 'seq'

DeeJayStore = (key_prefix) ->
  @key_prefix = "deejay:" 

_.extend(DeeJayStore.prototype, {
    
  findAll: (options) ->
    console.log("starting to find all")
    Seq()
      .seq_((next) ->
        R.keys "deejay:????????-????-????-????-????????????", next
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
    SS.log.error.message("deejay store find")
    if _.isString(model)
     id = model
    else if model
     id = model.id
   
    R.hgetall @key_prefix + id, (err, response) ->
      if _.isEmpty(response) || err
        options.error("User not found")
      else
        options.success(response)
        
  create: (model, options) ->
    success = (resp) ->
       if _.isFunction(options.success)
         options.success(resp)
    
    key_prefix = @key_prefix
    model.id = uuid()
    Seq()
      .par_((next) -> R.exists key_prefix + model.id, next)
      .par_((next) -> R.hexists key_prefix + "emails", model.get("email"), next)
      .par_((next) -> R.hexists key_prefix + "names", model.get("name") , next)
      .seq_((next, key_exists, email_exists, name_exists) ->
        if (key_exists)
          next("key exists")
        else if (email_exists)
          next("email exists")
        else if (name_exists)
          next("name exists")
        else
          next()
      ).seq_((next) ->
        write_transaction = R.multi();
        timestamp = {created_at: Date.now()}
        model.attributes = _.extend(model.attributes, timestamp)

        write_transaction.hsetnx "deejay:emails", model.get("email"), model.id
        write_transaction.hsetnx "deejay:names", model.get("name"), model.id
        write_transaction.hmset key_prefix + model.id, model.toJSON()
        
        write_transaction.exec (err, replies) ->
          if replies == null || err
            next("Object could not be saved. Please try again")
          else
            success(timestamp)
      )
      .catch((err) ->
        if options.error
          options.error err
        else
          SS.log.error.message(err)
      )
      
    return undefined
    
  update: (model, options) ->
    SS.log.error.message("deejay store update")
    # we need to prevent that the user changes the email to his account, maybe it is better ONLY use emails - and don't use any id's for the user - but i guess that it would
    # be nicer to support multiple emails and accounts for authentication bringing a little more complexity
    
    timestamp = {updated_at: Date.now()}
    changes = _.extend(model.changedAttributes(), timestamp)
    key_prefix = "deejay:"
    
    if !model.hasChanged()
      options.success(false)
    else
      #start watching keys 
      Seq()
        # watching all relevant keys if neccecary to provide optimistic locking for changes to this record
        .par_((next)->
          R.watch key_prefix + model.id, next
        )
        .par_((next)->
          if model.hasChanged("email")
             R.watch key_prefix + "emails", next
          else
            next()
        )
        .par_((next)->
          if model.hasChanged("name")
             R.watch key_prefix + "names", next
          else
            next()
        )
        .seq_((next, hash, email, name) ->
          next()
        )
        .par_((next) -> 
          if model.hasChanged("email")
            R.hget key_prefix + "emails", changes["email"], next
          else
            next()
        )
        .par_((next) -> 
          if model.hasChanged("name")
            R.hget key_prefix + "names", changes["name"], next
          else
            next()
        )
        .seq_((next, id_by_email, id_by_name) ->
          errors = []
          if _.isString(id_by_email) && id_by_email != model.id
            errors.push "email is already in use by another deejay"
  
          if _.isString(id_by_name) && id_by_name != model.id
             errors.push "name is already in use by another deejay"
  
          if errors.length > 0
            R.unwatch key_prefix + model.id, key_prefix + "emails", key_prefix + "names"
            next errors
          else
            next()
        )
        .seq((next) ->
          write_transaction = R.multi();

          write_transaction.hmset key_prefix + model.id, changes
                
          if model.hasChanged("email")
            write_transaction.hset "deejay:emails", changes["email"], model.id 
            write_transaction.hdel "deejay:emails", model.previous("email")
          if model.hasChanged("name")
            write_transaction.hset "deejay:names", changes["name"], model.id
            write_transaction.hdel "deejay:names", model.previous("name")

          write_transaction.exec (err, replies) ->
            if err || replies == null 
              next "Object could not be saved. Please try again"
            else
              options.success(timestamp) if _.isFunction(options.success)
        )
        .catch((err) ->
          if options.error
            options.error err
          else
            SS.log.error.message(err)
        )
      return undefined

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