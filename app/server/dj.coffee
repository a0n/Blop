# Server-side Code

SS.require "models/dj.coffee"

exports.actions =

  find: (id, cb) ->
    x = new SS.models.dj()
    x.id = id
    x.fetch({
      success: (model, response) ->
        console.log("Running Success callback from fetch method")
        cb model.toJSON()
      error: (model, error) ->
        console.log("Running Error callback from fetch method")
        cb error
    })

  create: (params, cb) ->
    x = new SS.models.dj(params)
    x.save({}, {
      success: (model, response) ->
        console.log("Created DJ")
        cb {success: true, created_at: model.get("created_at")}
      error: (model, error) ->
        console.log("Created error DJ")
        cb {error: true, messages: error}
    })
    
  delete: (id, cb) ->
    
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