# Server-side Code
_ = require('underscore')._
SS.require "models/server.coffee"

get_dj = (dj_id, cb) ->
  dj = new SS.models.deejay()
  dj.id = dj_id
  
  dj.fetch({
    success: (model, response) ->
      cb null, model
    error: (model, error) ->  
      SS.log.error.message(error)
      cb {error: true, message: error}
  })

exports.actions =
  get: (id, cb) ->
    get_dj id, (err, dj) ->
      if err
        cb err
      else
        cb dj

  create: (params, cb) ->
    x = new SS.models.deejay(params)
    x.save({}, {
      success: (model, response) ->
        cb _.extend(response, {id: model.id})
      error: (model, error) ->
        cb {error: true, messages: error}
    })
    return undefined
    
  update: (id, params, cb) ->
    unless _.isString(@session.user_id)
      cb "You must be authenticated to change a User"
    else if @session.user_id != id
      cb "You must only change your own user"
    else
      get_dj id, (err, dj) ->
        if err
          cb err
        else
          SS.log.error.message("Running Success callback from update method in fetch part")
          x.change()
          #x.set(params, {silent: true})
        
          x.save(params, {
            silent: true
            success: (model, response) ->
              SS.log.error.message("Created DJ")
              console.log(model)
              cb response
            error: (model, error) ->
              SS.log.error.message("Created error DJ")
              cb {error: true, messages: error}
          })
    
  delete: (id, cb) ->
    unless _.isString(@session.user_id)
      cb "You must be authenticated to delete a User"
    else if @session.user_id != id
      cb "You must only delete your own user"
    else
      x = new SS.models.deejay()
      x.id = id
      x.fetch({
        success: (model, resp) ->
          SS.log.error.message("Running Error callback in dj controller from delete method in fetch part")
          model.destroy({
            success: (model, response) ->
              SS.log.error.message("Running Success callback in dj controller from delete method in delete part")
              cb model.toJSON()
            error: (model, error) ->
              SS.log.error.message("Running Error callback in dj controller from delete method in delete part")
              cb error
          })
        error: (model, error) ->
          SS.log.error.message("Running Error callback in dj controller from delete method in fetch part")
          cb error
      })
    
  authenticate: (params, cb) ->
    @session.authenticate 'user_auth', params, (response) =>
      @session.setUserId(response.user_id) if response.success
      cb(response)
      
      
  deauthenticate: (cb) ->
    unless _.isString(@session.user_id)
      cb "You are not authenticated, thus cannot deauthenticate"
    else
      @session.user.logout(cb)
  
  user_session: (cb) ->
    unless _.isString(@session.user_id)
      delete @session.user_id
    cb @session
      
  activity: (cb) ->
    
  given_probs: (cb) ->
    
  received_probs: (cb) ->
  
  mentions: (cb) ->
  
  tags: (cb) ->
    
  followers: (cb) ->
    
  following: (cb) ->

  blips: (cb) ->
    
  feed: (cb) ->
    
  #write methods
  follow: (dj_id, cb) ->
    dj_to_follow = new DJ()
    dj_to_follow.id = dj_id
    
    dj_to_follow.fetch({
      success: (model, response) ->
        model.add 
      error: (model, error) ->
        cb {error: true, message: "DJ Does not exists"}
    })
    
  unfollow: (cb) ->
    dj_to_follow = new DJ()
    dj_to_follow.id = dj_id
    
    dj_to_follow.fetch({
      success: (model, response) ->
        model.add 
      error: (model, error) ->
        cb {error: true, message: "DJ Does not exists"}
    })