---
layout: post
title: "Preloading associations on an Array of Objects"
date: 2023-01-04
categories: rails
excerpt: "It might happen that your initial array of objects is not an ActiveRecord Relation. You cannot use preload on an array of objects and therefore you suffer of N+1 queries. Here is the solution."
---

It might happen that your initial array of objects is not an ActiveRecord Relation.
You cannot use `preload` on an array of objects and therefore you suffer of N+1 queries.

Imagine we have a Restaurants list. The Restaurants are fetched from a remote Service and therefore we have a simple array of objects.

In our system we have `Customer`s and they reference the `Restaurant` by `external_restaurant_id`.

This is the setup. There might be a lot of reasons why you cannot cache the restaurants locally of course.

```ruby
class Restaurant
  def initialize(json)
    @json = json
  end

  def code = @json[:code]
  def name = @json[:name]
end
```

```ruby
class Customer < ApplicationRecord
  
end
```

This is the partial that renders our restaurants:

```erb
<% @restaurants.each do |restaurant| %>
  <div class="card">
    <h5><%= restaurant.name %></h5>
    <hr>
    <h4>Customers list</h4>
    <% Customer.where(external_restaurant_code: restaurant.code).each do |customer| %>
      <%= customer.name %>
    <% end %>
  </div>
<% end %>
```

This causes clearly N+1 queries (more correctly just N, because there's no +1, since the restaurants are fetched remotely)

```
Customer Load (0.1ms)  SELECT "customers".* FROM "customers" WHERE "customers"."external_restaurant_code" = ?  [["external_restaurant_code", 1]]
  ↳ app/views/restaurants/index.html.erb:7
Customer Load (0.0ms)  SELECT "customers".* FROM "customers" WHERE "customers"."external_restaurant_code" = ?  [["external_restaurant_code", 2]]
  ↳ app/views/restaurants/index.html.erb:7
Customer Load (0.0ms)  SELECT "customers".* FROM "customers" WHERE "customers"."external_restaurant_code" = ?  [["external_restaurant_code", 3]]
  ↳ app/views/restaurants/index.html.erb:7
...
```

How can we avoid performing multiple queries? The Restaurant is not an ActiveRecord model, therefore we cannot do something like `Restaurant.includes(:customers).each`.

Our first approach was to just reimplement the preloading and do the following in the controller:

```ruby
@restaurants = Restaurant.from_api
@customers = Customer.where(external_restaurant_code: @restaurants.map(&:code)).group_by(&:external_restaurant_code)
```

This solves already our problem and removes the repeated queries:

```
Customer Load (0.7ms)  SELECT "customers".* FROM "customers" WHERE "customers"."external_restaurant_code" IN (?, ?, ?)  [["external_restaurant_code", 1], ["external_restaurant_code", 2], ["external_restaurant_code", 3]]
```

but the code smells quite a bit: we are basically re-implementing eager loading ourselves and we are moving in the controller a lot of business logic. The example is rather easy, but it might get much more complex very fast.

Our solution consists of making the Restaurant an ActiveRecord object. Here is an example:

```ruby
class WrappedRestaurant < ApplicationRecord
  attr_reader :restaurant

  has_many :customers, foreign_key: :external_restaurant_code, primary_key: :code

  def initialize(restaurant)
    @restaurant = restaurant
    super(code: restaurant.code)
  end

  def readonly? = true
end
```

We can now do the following:

```ruby 
@restaurants = Restaurant.from_api.map { |r| WrappedRestaurant.new(r) }
```

and render our view like this:

```erb
<% @restaurants.each do |restaurant| %>
  <article>
    <h2><%= restaurant.name %></h2>
    <hr>
    <h5>Customers list</h5>
    <ul>
    <% restaurant.customers.each do |customer| %>
      <li><%= customer.name %></li>
    <% end %>
    </ul>
  </article>
<% end %>
```

Which is much more Rails-alike, but we are back to the initial issue:

```
Customer Load (0.1ms)  SELECT "customers".* FROM "customers" WHERE "customers"."external_restaurant_code" = ?  [["external_restaurant_code", 1]]
  ↳ app/views/restaurants/index.html.erb:7
Customer Load (0.0ms)  SELECT "customers".* FROM "customers" WHERE "customers"."external_restaurant_code" = ?  [["external_restaurant_code", 2]]
  ↳ app/views/restaurants/index.html.erb:7
Customer Load (0.0ms)  SELECT "customers".* FROM "customers" WHERE "customers"."external_restaurant_code" = ?  [["external_restaurant_code", 3]]
  ↳ app/views/restaurants/index.html.erb:7
...
```


The final step is to use the Rails preloader. This luckily accepts an array, so we can write the following:

```ruby
ActiveRecord::Associations::Preloader.new(records: @restaurants, associations: [:customers]).call
```

and our `customers` association will be preloaded. 🪄

We like to wrap-up everything in a nice method in the wrapper class:

```ruby
# wrapped_restaurant.rb
def self.wrap(restaurants, preload: [])
    restaurants.map { |restaurant| WrappedRestaurant.new(restaurant) }.tap do |wrapped_restaurants|
      ActiveRecord::Associations::Preloader.new(records: wrapped_restaurants, associations: preload).call if preload.any?
  end
end
```

You can now preload associations on your Restaurant and keep the logic within the WrappedRestaurant model. The only cons is that you need a "fake" table on the database, nothing that a good old comment cannot solve 😉.

Find the whole code at [https://github.com/coorasse/array_preloading_example](https://github.com/coorasse/array_preloading_example)
