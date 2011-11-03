Backbone = require 'backbone'

Backbone.sync = (method, model, options) ->
  resp = undefined
  store = model.redisStorage or model.collection.redisStorage
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
    #THIS USUALY NEVER HAPPENS BECAUSE THE ERRORS SHOULD BE CATCHED AND PROVIDED TO THE ERROR CALLBACK
    SS.log.error.message("Cathing Error in Backbone.sync", error)
    options.error(error)
    
module.exports = Backbone