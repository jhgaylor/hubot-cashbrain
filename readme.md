# including cashbrain

npm install hubot-cashbrain

and add a script like this to your hubot

    _ = require 'underscore'
    CashBrain = require 'hubot-cashbrain'

    module.exports = (robot) ->
      $brain = new CashBrain()
      robot.brain = _.extend $brain, robot.brain

# todo:
have the brain keep the cache up to date with setTimeouts
