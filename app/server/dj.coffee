# Server-side Code
_ = require('underscore')._
SS.require "models/dj.coffee"

exports.actions =
  get: (id, cb) ->
    x = new SS.models.dj()
    x.id = id
    x.fetch({
      success: (model, response) ->
        SS.log.error.message("Running Success callback from fetch method")
        cb model.toJSON()
      error: (model, error) ->
        SS.log.error.message("Running Error callback from fetch method")
        cb error
    })

  create: (params, cb) ->
    x = new SS.models.dj(params)
    x.save({}, {
      success: (model, response) ->
        SS.log.error.message("Created DJ")
        cb _.extend(response, {id: model.id})
      error: (model, error) ->
        SS.log.error.message("Created error DJ")
        cb {error: true, messages: error}
    })
    return undefined
    
  update: (id, params, cb) ->
    x = new SS.models.dj()
    x.id = id
    x.fetch({
      success: (model, resp) ->
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
        
      error: (model, error) ->
        SS.log.error.message("Running Error callback from update method in fetch part")
        cb error
    })
    
  delete: (id, cb) ->
    x = new SS.models.dj()
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
    @session.user.logout(cb)
      
  activity: (cb) ->
    try
      test = 123
      ->
        throw "test error"
      cb true
    catch error
      cb error
    
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