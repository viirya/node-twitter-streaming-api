
http = require('http')
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
prompt = require('prompt')
mongo = require('mongodb')
assert = require('assert')

Server = mongo.Server
Db = mongo.Db


options = cli.parse
  username: ['u', 'Your twitter username', 'string'],
  password: ['p', 'Your twitter password', 'string'],
  track: ['t', 'The keywords to track', 'string']

db_options =
    db_username: no
    db_password: no

streaming = ->

    #console.log(options)

    server = new Server('', 27017, {auto_reconnect: true})
    db = new Db('twitterDb', server)

    db.open((err, db) ->
        if (!err)
            db.authenticate(db_options.db_username, db_options.db_password, (err, result) ->
                assert.equal(true, result)
                
                db.collection('twitter_linsanity_nba', (err, collection) ->
                
                    TwitterStream = require('./lib/twitterstream').TwitterStream
                    
                    streamer = new TwitterStream(options)
                    
                    streamer.on 'tweet', (tweetText) ->
                        tweet = JSON.parse(tweetText)
                        #console.log(tweet)
                        if tweet.text?
                            console.log tweet.user.screen_name + ': ' + tweet.text
                            collection.insert(tweet, {safe:true}, (err, result) ->
                                assert.equal(null, err)
                            )
                        else if tweet.limit?
                            console.log tweetText
                        else
                            console.log 'ERROR'
                            console.log tweetText
                            throw 'unknown tweet type'
                )
            )
    )

prompt.start();
properties = [
        name: 'username', 
        validator: /^[a-zA-Z\s\-]+$/,
        warning: 'Name must be only letters, spaces, or dashes',
        empty: false
    ,
        name: 'password',
        hidden: true
    ,
        name: 'db_username', 
        validator: /^[a-zA-Z\s\-]+$/,
        warning: 'Name must be only letters, spaces, or dashes',
        empty: false
    ,
        name: 'db_password',
        hidden: true
 
];

prompt.get(properties, (err, result) ->
    options.username = result.username
    options.password = result.password
    db_options.db_username = result.db_username
    db_options.db_password = result.db_password
    streaming()
)
