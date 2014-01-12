# Description:
#   Modifies the base brain to add a second set of keys to the datastore
#   All cash keys start with $.
#   added api:
#     $get

#
# Dependencies:
#   "fibers/future": ""
#
# Commands:
#   None
#
# Author:
#   jhgaylor
Log = require 'log'
Future = require 'fibers/future'

class CashBrain

  constructor: ->
    @logger = new Log "info" # use env var
    @$refreshCallbacks = { }
    @$refreshLifespans = { }

  # return the inner function
  $refresh: (key, cb) =>
    # TODO: once this method is 'synchronous', it works!
    refreshCb = @$refreshCallbacks[key]
    new_value = refreshCb().wait()
    lifespan = @$refreshLifespans[key]
    @$set(key, new_value, lifespan)

    @logger.debug "fired callback with new value"
    cb and cb(new_value)

  $register: (key, refreshCb, life_in_seconds) ->
    # register a callback to fire when the cache invalidates
    if refreshCb
      @$refreshCallbacks[key] = Future.wrap(refreshCb)
    unless life_in_seconds
      life_in_seconds = 3600 # 1 hour
    @$refreshLifespans[key] = life_in_seconds

  $get: (key, cb, refreshCb, life_in_seconds) ->
    if refreshCb
      @$register key, refreshCb, life_in_seconds

    cached_data = @get("$#{key}")
    if cached_data and new Date() < cached_data.expiration
      @logger.debug "cache hit for key: #{key}"
      cb cached_data.data
    else
      @logger.debug "cache miss for key: #{key}"
      @$refresh.future()(key, cb)

  $set: (key, value, life_in_seconds) ->
    future_date = new Date()
    future_date.setSeconds(future_date.getSeconds()+life_in_seconds)
    @set "$#{key}",
      expiration: future_date,
      data: value

module.exports = CashBrain
