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
  toString: ->
    "<< CashBrain >>"

  $logger: new Log "debug" # use env var
  $refreshCallbacks: { }
  $refreshLifespans: { }

  # return the inner function
  $refresh: (key, cb) =>
    @$logger.debug "$refresh called"
    # TODO: once this method is 'synchronous', it works!
    refreshCb = @$refreshCallbacks[key]
    @$logger.debug "preparing to wait on refreshCb"
    new_value = refreshCb().wait()
    @$logger.debug "done waiting on refreshCb"
    lifespan = @$refreshLifespans[key]

    @$logger.debug "fired callback with new value"
    cb and cb(new_value)

    @$logger.debug "setting cache with new value"
    @$set(key, new_value, lifespan)


  $register: (key, refreshCb, life_in_seconds) ->
    @$logger.debug "$register called"
    # register a callback to fire when the cache invalidates
    if refreshCb
      @$refreshCallbacks[key] = Future.wrap(refreshCb)
    unless life_in_seconds
      life_in_seconds = 3600 # 1 hour
    @$refreshLifespans[key] = life_in_seconds

  $get: (key, cb, refreshCb, life_in_seconds) ->
    @$logger.debug "$get called"
    if refreshCb
      @$register key, refreshCb, life_in_seconds

    @$logger.debug "get called on #{key}"
    cached_data = @get("$#{key}")
    if cached_data and new Date() < cached_data.expiration
      @$logger.info "cache hit for key: #{key}"
      cb cached_data.data
    else
      @$logger.info "cache miss for key: #{key}"
      @$refresh.future()(key, cb)

  $set: (key, value, life_in_seconds) ->
    @$logger.debug "@set called"
    future_date = new Date()
    @$logger.debug "future date set"
    future_date.setSeconds(future_date.getSeconds()+life_in_seconds)
    @$logger.debug "future date modified"
    @set "$#{key}",
      expiration: future_date,
      data: value
    @$logger.debug "@set returned"

module.exports = CashBrain
