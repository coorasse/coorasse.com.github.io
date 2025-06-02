---
layout: post
title: "CanCanCan 3.2.0"
date: 2020-12-12
categories: rails
excerpt: "Hi all 👋, a new version of CanCanCan is out!
Again, we have a minor release but it includes a bunch of very important features, next to support for Rails 6.1.0."
---

Hi all 👋,
a new version of CanCanCan is out!

Again, we have a minor release but it includes a bunch of very important features, next to support for Rails 6.1.0.

I have [opened a sponsorship program](https://github.com/sponsors/coorasse), please consider supporting the project if you use CanCanCan. It really helps!

## Switching query strategy

Since version 3.0.0 we started changing the way we perform the queries when using `accessible_by`, in order to be more performant and reliable.

As expected, this new way of performing the queries didn't fit everyone, so in version 3.1.0 we switched from `left_joins` to `subqueries` ([see relevant PR](https://github.com/CanCanCommunity/cancancan/pull/605)).

This again didn't make everyone happy 😃 , so we decided, in the version 3.2.0 to allow to configure the preferred query mechanism: left joins or inner queries.

You can now setup:
```ruby
CanCan.accessible_by_strategy = :subquery # or :left_join
```

to change it.

## Support for Single Table Inheritance

Single Table Inheritance is now supported. Given the following:

```ruby
class Vehicle < ApplicationRecord

class Car < Vehicle

class Motorbike < Vehicle
```

You can play with rules by defining:

```ruby
can :read, Vehicle
```

and query for:

```ruby
Vehicle.accessible_by
# or
Motorbike.accessible_by
```

Here is an example:

```ruby
can :read, Motorbike

Vehicle.accessible_by(...) # => returns only motorbikes
```

Check the [relevant PR](https://github.com/CanCanCommunity/cancancan/pull/649/files) for more examples and note that [there are currently some minor issues](https://github.com/CanCanCommunity/cancancan/pull/663)

## Support for associations in rules definition

When using associations in rules definition you always had to use column names. Now, [thanks to this PR](https://github.com/CanCanCommunity/cancancan/pull/650) you can also use the association name.

```ruby
# previously you had to define:
can :edit, Book, author_id: user.id

# now you can also write:
can :edit, Book, author: user
```

Enjoy! And to the next one...

