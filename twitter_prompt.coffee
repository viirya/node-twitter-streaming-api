http = require('http')
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
prompt = require('prompt');

options = cli.parse
  username: ['u', 'Your twitter username', 'string'],
  password: ['p', 'Your twitter password', 'string'],
  track: ['t', 'The keywords to track', 'string']

streaming = ->

    #console.log(options)

    TwitterStream = require('./lib/twitterstream').TwitterStream

    streamer = new TwitterStream(options)

    streamer.on 'tweet', (tweetText) ->
        tweet = JSON.parse(tweetText)
        console.log(tweet)
        if tweet.text?
            console.log tweet.user.screen_name + ': ' + tweet.text
        else if tweet.limit?
            console.log tweetText
        else
            console.log 'ERROR'
            console.log tweetText
            throw 'unknown tweet type'


prompt.start();
properties = [
        name: 'username', 
        validator: /^[a-zA-Z\s\-]+$/,
        warning: 'Name must be only letters, spaces, or dashes',
        empty: false
    ,
        name: 'password',
        hidden: true
];

prompt.get(properties, (err, result) ->
    options.username = result.username
    options.password = result.password
    streaming()
)
