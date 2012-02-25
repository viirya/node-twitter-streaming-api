# Extending Twitter Streaming API Sample

This program extends [mthomas/node-twitter-streaming-api](https://github.com/mthomas/node-twitter-streaming-api) that is a sample of using the twitter streaming API with Node.js, written in Coffeescript.

## Modification

This program prompts user to input username and password for Twitter account instead of giving in command line parameters. It stores crawled tweets in Mongodb backend. So it also prompts username and password for Mongodb authentication.

## Usage

Node.js modules usead: underscore, cli, line-parser, prompt, and mongodb.

To run:

* npm install coffee-script -g
* npm install
* coffee twitter_prompt.coffee -t comma,separated,words,to,track




