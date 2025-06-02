---
layout: post
title: "Log API requests in Rails"
date: 2021-02-24
categories: rails
excerpt: "When exposing or consuming APIs, one of the most important things to remember is to log the calls you perform."
---

When exposing or consuming APIs, one of the most important things to remember is to log the calls you perform.

It will not take long until you will have to answer the question "What happened? And why?".

Having a proper log of the API requests you performed or received is the only way to answer these questions.

That's why at [Renuo](https://renuo.ch), we extracted [rails_api_logger](https://github.com/renuo/rails_api_logger) from our projects and made it open source.

**rails_api_logger** is a library that can be used for logging both inbound requests and outbound requests.

Please read the README file for a full documentation. Here I will sum it up quickly.

# Log Inbound Requests

If you are exposing APIs you can log the requests you receive. Use the following Middleware:

```ruby
config.middleware.insert_before Rails::Rack::Logger, InboundRequestLoggerMiddleware

```

Check the [README](https://github.com/renuo/rails_api_logger) for further options.

# Log Outbound Requests

Given the following outbound request:

```ruby
uri = URI('http://example.com/some_path?query=string')
http = Net::HTTP.start(uri.host, uri.port)
request = Net::HTTP::Get.new(uri)
response = http.request(request)
```

you can log it by doing the following:

```ruby
uri = URI('http://example.com/some_path?query=string')
http = Net::HTTP.start(uri.host, uri.port)
request = Net::HTTP::Get.new(uri)
response = RailsApiLogger.call(uri, http, request)
```

The gem comes with a first code example to integrate these logs in RailsAdmin. It the future we will release more and more features.

Head to [rails_api_logger](https://github.com/renuo/rails_api_logger) on GitHub and give it a ⭐️!
