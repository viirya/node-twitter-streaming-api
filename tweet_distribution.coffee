
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
prompt = require('prompt')
mongo = require('mongodb')
assert = require('assert')
fs = require('fs')

Server = mongo.Server
Db = mongo.Db

options = cli.parse
  outfile: ['o', 'The output filename', 'string']

db_options =
    db_username: no
    db_password: no

query = ->

    #console.log(options)

    server = new Server('', 27017, {auto_reconnect: true})
    db = new Db('twitterDb', server)

    db.open((err, db) ->
        if (!err)
            db.authenticate(db_options.db_username, db_options.db_password, (err, result) ->
                assert.equal(true, result)
                
                db.collection('twitter_linsanity_nba', (err, collection) ->

                    stream = collection.find({}, {id_str: true, created_at: true}).sort({created_at: 1}).streamRecords();

                    tweet_count = 0
                    tweet_messages = ""
                    stream.on("data", (item) ->
                        console.log(item.created_at)
                        tweet_count++
                        tweet_messages += item.created_at + " : " + item.id_str + "\n"
                    )

                    stream.on("end", ->
                        console.log("total: " + tweet_count + " tweets")
                        fs.writeFile(options.outfile, tweet_messages, (err) ->
                            if (err)
                                throw err
                            process.exit()
                        )
                    )
                    
                
                )
            )
    )

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
    query()
)
