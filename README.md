hare -- A command-line tool in Ruby to interact with message queues
===================================================================

Introduction
------------

Life with an AMQP message bus is dandy. `hare` exists to augment that
experience, allowing cron scripts and other system utilies to fire and
forget messages over the message bus or to receive messages to
stdout. `hare` is to RabbitMQ as `mailx` is to postfix.

Installation
------------

Assuming you have a Ruby environment available, it's as simple as:

    gem install hare

If not, consider the use of
[rbenv](https://github.com/sstephenson/rbenv) or
[rvm](http://beginrescueend.com/).

Example Usage
-------------

We'll send a message over the localhost message bus, exchange 'events', vhost '/' with route-key 'dev.event'. First, get a `hare` into listener mode:

    $ hare --exchange_name events --route_key dev.event

and we'll send a message:

    $ hare --exchange_name events --route_key dev.event --producer "that wasn't so bad"

Miscellania
-----------

`hare` has been developed as a part of my work with
[CarePilot](https://www.carepilot.com) and is released under the MIT
license. `hare` uses [semantic versioning](http://semver.org/).
