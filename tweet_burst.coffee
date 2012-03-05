
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
assert = require('assert')
fs = require('fs')
lazy    = require("lazy")

options = cli.parse
    filename: ['f', 'The filename to parse', 'string']
    window: ['w', 'The window size', 'number', 30]  
    #outfile: ['o', 'The output filename', 'string']
 
tweet_number = {}
start_time = 0
start_day = 0
month_number = 0
pre_day = 0

new lazy(fs.createReadStream(options.filename))
    .lines
    .forEach((line) ->
        tweet_time = line.toString()

        regex = /.*?\s(\d*)\s(\d*):(\d*):(\d*)\s(.*?)\s(.*)\s:\s(\d*)/
        match = regex.exec(tweet_time)

        day = match[1]
        hour = match[2]
        min = match[3]
        sec = match[4]
        id = match[7]

        #console.log(id + " " + day + " " + hour + ":" + min + ":" + sec)

        if (start_day == 0)
            start_day = day

        if (pre_day != 0 && parseInt(day) < parseInt(pre_day))
            month_number++

        pre_day = day

        time = parseInt(sec) + parseInt(min) * 60 + parseInt(hour) * 60 * 60 + (parseInt(day) - parseInt(start_day)) * 24 * 60 * 60 + month_number * 31 * 24 * 60 * 60

        if (start_time == 0)
            start_time = time

        slot = Math.ceil((time - start_time) / options.window)

        assert.equal(true, slot >= 0)

        # if (slot < 0)
        #    console.log(day + " - " + start_day + " = " + (parseInt(day) - parseInt(start_day)))
        #    console.log(time + " - " + start_time + " = " + (time - start_time))

        if (tweet_number[slot])
            tweet_number[slot]++
        else
            tweet_number[slot] = 1
  
        #console.log(slot)

    ).on('end', ->
        console.log(tweet_number)

        ###
        fs.createWriteStream(options.outfile).on('open', (fd) ->
            for time, tweet of hash
                console.log(time + ": " + tweet)                    
                this.write(time + "\t" + tweet + "\n")
        )
        ###
        
    )
    



