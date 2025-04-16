---
layout: post
title: "Single Table Inheritance tips"
date: 2025-04-16
categories: rails
excerpt: "Two small tricks I recently discovered when working with STI"
---

Single Table Inheritance is great.
Possible because even if I don't work Java since at least 14 years, I still love inheritance in OOP.

I recently played around with STI in Rails and want to share a couple of small tricks:

```ruby

class Server

end

class HerokuServer
  def host = "herokuapp.com"
end

class GenericServer
  def host = "sslip.io"
end

class ServersController
  def show
    @server = Server.find(params[:id])
  end
end
```

First important thing is that `@server` will be an instance of either `HerokuServer` or `GenericServer`.

Rails assigns the correct class automatically even if you call `Server.find`. This is pretty smart and useful, so
we can call `@server.host`.

But our path helpers are broken now.

In fact I have a generic `ServerController` and my routes.rb defines:

```ruby
resources :servers
```

So when we use

```erb
<%= link_to [:edit, @server] %>
```

it will inevitably fail with:

```
NoMethodError - undefined method `edit_generic_server_path' for #<ActionView::Base:0x00000000021ea8>
```

we can fix this in some different ways:

```ruby
@server = Server.find(params[:id]).becomes(Server)
```

but now our `@server` cannot respond to `.host` anymore. Alternatively, we can use an explicit path helper:

```erb
<%= link_to edit_server_path(@server) %>
```

or use `.becomes` only when we need it:

```erb
<%= link_to [:edit, @server.becomes(Server)] %>
```

but with both these approaches it means we have to change it everywhere.

The last possible approach is to override the method `model_name`.

```ruby

class GenericServer
  def self.model_name
    Server.model_name
  end
end
```  

but we might not want to define this in all our subclasses, so let's define this on the `Server` class instead:

```ruby

class Server
  def self.model_name
    ActiveModel::Name.new(self, nil, 'Server')
  end
end
```

You can now keep using all the generic path helpers, but also keep the `@server` object behaving as its own specific
subclass. 
