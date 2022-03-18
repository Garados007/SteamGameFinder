# Steam Game Finder

You know it, I know it. I think everyone knows it. You want to play something with your friends but
you don't know what. You all have big steam libraries with many unknown, new or nostalgic games but
it is quite troublesome to find what you really want to play. Especially if you are more than two
friends or one got new pocket money and wants to buy new games.

This is a (partial) solution for this! Just enter in the web front end your 64 bit Steam Ids and
you get a nice overview of your games. Afterwards everyone picks their favorites until you have a
small list left what you can play.

## Install

There is a docker file. Just start it. You need to expose port 8000 to some well known port (can be
different from 8000). Than you need to set your [Steam Api Key](https://steamcommunity.com/dev/registerkey)
as environment variable `PLAY_API_KEY`.
