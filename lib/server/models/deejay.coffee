_ = require('underscore')._
Backbone = SS.require("backbone-redis.coffee")
DeeJayStore = SS.require("sync_models/deejay")


Followers = Backbone.Collection.extend ({
  model: DeeJay
  redisStorage: new DeeJayStore("deejay")
})

Following = Backbone.Collection.extend ({
  model: DeeJay
  redisStorage: new DeeJayStore("deejay")
})


DeeJay = Backbone.Model.extend ({
  initialize: () ->
    @followers = new Followers()
    @followers.extend({parrent: @})
    
    @following = new Following()
    @following.extend({parrent: @})
    
  redisStorage: new DeeJayStore("deejay")
    
  # must validate fields in O(1) all calls that need to validate something against the db has to be in the sync method
  validate: (attrs) ->
    errors = []
    attributes = _.extend(@attributes, attrs)
    non_allowed_keys = _.difference(_.keys(_.extend(@attributes, attrs)), ["id", "email", "pw", "name", "created_at", "updated_at"])
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
      SS.log.error.message("VALIDATION ERROR!")
      console.log(errors)
      return {error: true, message: errors}
    else
      return null
 
})

module.exports = DeeJay