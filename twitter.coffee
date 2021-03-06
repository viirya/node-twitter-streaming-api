http = require('http')
Buffer = require('buffer').Buffer
EventEmitter = require('events').EventEmitter
_ = require('underscore')
cli = require('cli')
rl = require('readline')
prompt = require('prompt');

ask = (question, format, callback) ->

    stdin = process.openStdin()
    stdout = process.stdout

    require('tty').setRawMode(true)
    stdin.resume
 
    stdout.write(question + ": ")

    stdin.once('data', (data) ->
        data = data.toString().trim()
        if (format.test(data)) 
            callback(data)
        else
            stdout.write("It should match: "+ format +"\n")
            ask(question, format, callback)
    )
    

options = cli.parse
  username: ['u', 'Your twitter username', 'string'],
  password: ['p', 'Your twitter password', 'string'],
  track: ['t', 'The keywords to track', 'string']


streaming = ->

    console.log(options)

    TwitterStream = require('./lib/twitterstream').TwitterStream

    streamer = new TwitterStream(options)

    streamer.on 'tweet', (tweetText) ->
        tweet = JSON.parse(tweetText)
        if tweet.text?
            console.log tweet.user.screen_name + ': ' + tweet.text
        else if tweet.limit?
            console.log tweetText
        else
            console.log 'ERROR'
            console.log tweetText
            throw 'unknown tweet type'


ask("username", /.+/, (username) ->
  ask("password", /.+/, (password) -> 
    options.username = username
    options.password = password
    streaming()
  )
) 
