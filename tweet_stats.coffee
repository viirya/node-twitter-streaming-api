
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
assert = require('assert')
fs = require('fs')
lazy    = require("lazy")

options = cli.parse
  filename: ['f', 'The filename to parse', 'string']
  outfile: ['o', 'The output filename', 'string']
 
hash = {}

new lazy(fs.createReadStream(options.filename))
    .lines
    .forEach((line) ->
        tweet_time = line.toString()

        regex = /.*?\s(\d*)\s(\d*):(\d*):(\d*)\s/
        match = regex.exec(tweet_time)

        day = match[1]
        hour = match[2]
        min = match[3]
        sec = match[4]

        # console.log(day + " " + hour + ":" + min + ":" + sec)

        if (hash[day + hour + min])
            hash[day + hour + min]++
        else
            hash[day + hour + min] = 1    
    ).on('end', ->
        #console.log(hash)
 
        fs.createWriteStream(options.outfile).on('open', (fd) ->
            for time, tweet of hash
                console.log(time + ": " + tweet)                    
                this.write(time + "\t" + tweet + "\n")
        )
        
    )
    



