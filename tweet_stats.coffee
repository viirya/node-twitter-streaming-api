
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
assert = require('assert')
fs = require('fs')
lazy    = require("lazy")

options = cli.parse
    filename: ['f', 'The filename to parse', 'string']
    highlight_file: ['h', 'The highlight filename', 'string']
    outfile: ['o', 'The output filename', 'string']

highlight_tweets = {}

if (options.highlight_file?) 
    new lazy(fs.createReadStream(options.highlight_file))
        .lines
        .forEach((line) ->
            highlight = line.toString()
        
            regex = /highlight:\s\d*\s(\d*)/
            match = regex.exec(highlight)
        
            tweet_id = match[1]
            highlight_tweets[tweet_id] = 1 
        )

parse_line = (line) ->

    regex = /.*?\s(.*?)\s(\d*)\s(\d*):(\d*):(\d*)\s(.*?)\s(.*)\s:\s(\d*)/
    match = regex.exec(line)

    tweet =
        month: match[1]
        day: match[2]
        hour: match[3]
        min: match[4]
        sec: match[5]
        id: match[8]

hash = {}
 
set_hash = (hash, day, hour, min) ->
    if (hash[day + hour + min]?)
        hash[day + hour + min]++
    else
        hash[day + hour + min] = 1 
    return hash
 
new lazy(fs.createReadStream(options.filename))
    .lines
    .forEach((line) ->
        tweet_time = line.toString()

        #regex = /.*?\s(\d*)\s(\d*):(\d*):(\d*)\s/
        #match = regex.exec(tweet_time)

        #day = match[1]
        #hour = match[2]
        #min = match[3]
        #sec = match[4]
        
        tweet = parse_line(tweet_time)

        # console.log(day + " " + hour + ":" + min + ":" + sec)

        # provided with highlight file
        if (options.highlight_file?)
            if (highlight_tweets[tweet.id]?)
                hash = set_hash(hash, tweet.day, tweet.hour, tweet.min)
            else
                if (!hash[tweet.day + tweet.hour + tweet.min]?)
                    hash[tweet.day + tweet.hour + tweet.min] = 0
        else
            hash = set_hash(hash, tweet.day, tweet.hour, tweet.min)
   
    ).on('end', ->
        #console.log(hash)
 
        fs.createWriteStream(options.outfile).on('open', (fd) ->
            for time, tweet of hash
                console.log(time + ": " + tweet)                    
                this.write(time + "\t" + tweet + "\n")
        )
        
    )
    



