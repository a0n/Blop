_ = require('underscore')._
Backbone = SS.require("backbone-redis.coffee")

DeeJay = SS.require "models/deejay.coffee"
ObjectStore = SS.require "sync_models/object_store.coffee"

DeeJays = Backbone.Collection.extend ({
  model: DeeJay
  redisStorage: new ObjectStore({model_name: "dj"})
})

Server = Backbone.Model.extend ({ 
  initialize: () ->
    @deejays = new DeeJays()
})

_.extend(SS.models, {server: Server, deejay: DeeJay})