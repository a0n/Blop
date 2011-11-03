_ = require('underscore')._
Backbone = SS.require("backbone-redis.coffee")
uuid = require 'node-uuid'
Seq = require 'seq'

DeeJay = SS.require "models/deejay.coffee"
DeeJayStore = SS.require "sync_models/deejay.coffee"

DeeJays = Backbone.Collection.extend ({
  model: DeeJay
  redisStorage: new DeeJayStore("dj")
})

Server = Backbone.Model.extend ({ 
  initialize: () ->
    @deejays = new DeeJays()
    @deejays.extend({parrent: @})
})

_.extend(SS.models, {server: Server, deejay: DeeJay})