
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
assert = require('assert')
fs = require('fs')
lazy    = require("lazy")
prompt = require('prompt')
mongo = require('mongodb')

options = cli.parse
    highlight_file: ['h', 'The highlight filename', 'string']
    outfile: ['o', 'The output filename', 'string']

highlight_tweets = {}

Server = mongo.Server
Db = mongo.Db

db_options =
    db_username: no
    db_password: no

highlight_tweet_content = {}

run = () ->
   
    server = new Server('', 27017, {auto_reconnect: true})
    db = new Db('twitterDb', server)

    db.open((err, db) ->
        if (!err)
            db.authenticate(db_options.db_username, db_options.db_password, (err, result) ->
                assert.equal(true, result)

                db.collection('twitter_linsanity_nba', (err, collection) ->

                    for highlight_id, tweet_ids of highlight_tweets
                        for tweet_id in tweet_ids

                            stream = collection.find({id_str: tweet_id}, {text: true}).streamRecords();
                            stream.on("data", (item) ->

                                console.log(item.text)

                                if (!highlight_tweet_content[highlight_id]?)
                                    highlight_tweet_content[highlight_id] = []

                                highlight_tweet_content[highlight_id].push(item.text)
                            )

                )
            )
    )
 
prompt_start = ->

    prompt.start();
    properties = [
            name: 'db_username',
            validator: /^[a-zA-Z\s\-]+$/,
            warning: 'Name must be only letters, spaces, or dashes',
            empty: false
        ,  
            name: 'db_password',
            hidden: true
        
    ];

    prompt.get(properties, (err, result) ->
        db_options.db_username = result.db_username
        db_options.db_password = result.db_password
        run()
    )
 
new lazy(fs.createReadStream(options.highlight_file))
    .lines
    .forEach((line) ->
        highlight = line.toString()

        regex = /highlight:\s(\d*)\s(\d*)/
        match = regex.exec(highlight)

        highlight_id = match[1]    
        tweet_id = match[2]

        if (!highlight_tweets[highlight_id]?)
            highlight_tweets[highlight_id] = []

        highlight_tweets[highlight_id].push(tweet_id) 

    ).on('end', ->
        prompt_start()
    )

