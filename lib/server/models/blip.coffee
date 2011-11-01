_ = require('underscore')._
Backbone = require('backbone')
rbytes = require("rbytes")

Blip = Backbone.Model.extend ({
  initialize: () ->
  
  # must validate fields in O(1) all calls that need to validate something against the db has to be in the sync method
  validate: (attrs) ->
    #if _.isUndefined(attrs["owner_id"])
    #  return "Topic can't be saved without an Owner"
    
    #if _.isUndefined(attrs["title"])
    #  return "Topic can't be saved without a title
    console.log(attrs)
    
  # Needs to be loaded as a Prototype for every Model this is the part that only lies on the server side it provides persitence between server and database
  # on the client siede an extra sync function provides persistence between client and server
  sync: (method, model, options) ->
    
    
    
      options.success(model)
  #  options.success(method)
})

module.exports = Blip