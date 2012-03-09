
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
assert = require('assert')
fs = require('fs')
lazy    = require("lazy")
prompt = require('prompt')
mongo = require('mongodb')

Object.prototype.size = () ->
    len = if this.length then --this.length else -1
    len++ for own k of this
    return len

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

                    # for highlight_id, tweet_ids of highlight_tweets
                        # for tweet_id in tweet_ids

                    console.log('hightlight: ', highlight_tweets.size())

                    write_output = ->
                        console.log('writing to output file.')
                        fs.createWriteStream(options.outfile).on('open', (fd) ->
                            for own highlight_id, tweets of highlight_tweet_content
                                for own tweet in tweets
                                    # console.log("highlight: " + highlight_id + "\t" + tweet + "\n")
                                    this.write("highlight: " + highlight_id + "\t" + tweet + "\n")
                            process.exit()
                        )


                    highlight_index = 0
                    set_stream_events = (coll, tweets, h_index) ->
                        stream = coll.find({id_str: {$in: tweets}}, {text: true}).stream();
                        stream.on("data", (item) ->
                        
                            # console.log(item.text)
                        
                            if (!highlight_tweet_content[h_index]?)
                                highlight_tweet_content[h_index] = []
                        
                            highlight_tweet_content[h_index].push(item.text)
                        )
                        stream.on("close", ->
                            h_index++
                            h_index++ until highlight_tweets[h_index]? || h_index > highlight_tweets.size()
                            if (highlight_tweets[h_index]?)
                                set_stream_events(coll, highlight_tweets[h_index], h_index)
                            else
                                console.log('fetch done')
                                console.log('events: ' + highlight_tweet_content.size())
                                write_output()
                                    
                        )

                    set_stream_events(collection, highlight_tweets[highlight_index], highlight_index)

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

