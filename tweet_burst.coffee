
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
assert = require('assert')
fs = require('fs')
lazy    = require("lazy")

Object.prototype.size = () ->
    len = if this.length then --this.length else -1
    len++ for own k of this
    return len

options = cli.parse
    filename: ['f', 'The filename to parse', 'string']
    window: ['w', 'The window size', 'number', 30]  
    outfile: ['o', 'The output filename', 'string']
    highlight_outfile: ['h', 'The highlight output filename', 'string']

months = {Jan: 1, Feb: 2, Mar: 3, Apr: 4, May: 5, Jun: 6, Jul: 7, Aug: 8, Sep: 9, Oct: 10, Nov: 11, Dec: 12}
 
tweet_number = {}
start_time = 0
start_day = 0
pre_slot = 0

mean = (tweets, slot_number) ->
    ret = 0
    for own index, number of tweets
        ret += number
    ret /= slot_number

std = (tweets, mean_value, slot_number) ->
    ret = 0
    #for own index, number of tweets
    for own index in [0..slot_number - 1]
        value = 0
        if (tweets[index]?)
            value = tweets[index]
        ret += Math.pow(value - mean_value, 2)
    ret = Math.sqrt(ret / slot_number)

parameter_alpha = 0.8
parameter_x = 1.8

tweet_ids = []
tweets = []
highlights = {}
hash = {}

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

get_time = (tweet) ->
    time = parseInt(tweet.sec) + parseInt(tweet.min) * 60 + parseInt(tweet.hour) * 60 * 60 + (parseInt(tweet.day) - parseInt(start_day)) * 24 * 60 * 60 + months[tweet.month] * 31 * 24 * 60 * 60
 
 
new lazy(fs.createReadStream(options.filename))
    .lines
    .forEach((line) ->
        tweet_time = line.toString()

        tweet = parse_line(tweet_time)

        # console.log(tweet)

        if (start_day == 0)
            start_day = tweet.day

        time = get_time(tweet)

        if (start_time == 0)
            start_time = time

        slot = Math.ceil((time - start_time) / options.window)

        assert.equal(true, slot >= 0)

        if (tweet_number[slot])
            tweet_number[slot]++
            pre_slot = slot
            tweet_ids.push(tweet.id)
            tweets.push(tweet)
        else
            if (tweet_number.size() > 0)
                mean_value = mean(tweet_number, pre_slot + 1)
                std_value = std(tweet_number, mean_value, pre_slot + 1)
                mt = parameter_alpha * (mean_value + parameter_x * std_value)

                if (tweet_number[pre_slot] > mt)
                    console.log("highlight detected.")
                    highlights[pre_slot] = tweet_ids

                    for own tweet in tweets
                        index = tweet.day + tweet.hour + tweet.min
                        if (hash[index])
                            hash[index]++
                        else
                            hash[index] = 1 

            tweet_number[slot] = 1
            tweet_ids = []
            tweets = []

    ).on('end', ->
        # console.log(highlights)

        fs.createWriteStream(options.outfile).on('open', (fd) ->
            highlight_count = 0

            for own slot_number, tweet_ids of highlights
                for own tweet_id in tweet_ids
                    console.log("highlight: " + highlight_count + "\t" + tweet_id + "\n")                    
                    this.write("highlight: " + highlight_count + "\t" + tweet_id + "\n")
                highlight_count++
        )

        fs.createWriteStream(options.highlight_outfile).on('open', (fd) ->
            for own time, tweet of hash
                console.log(time + ": " + tweet)
                this.write(time + "\t" + tweet + "\n")
        )
        
    )
    



