---
layout: post
title: "DatoCMS with Ruby on Rails"
date: 2022-04-04
categories: rails
excerpt: "How to integrate DatoCMS in your Ruby On Rails application."
---

At [Renuo](https://renuo.ch) we often need an HeadlessCMS in our Ruby On Rails projects, and in the last years, we had a great experience using [Dato CMS](https://www.datocms.com/).

So we decided to release our [DatoCMS client open source](https://github.com/renuo/dato-rails).

We extracted and isolated the features that we considered most useful and this tutorial will explain you, step-by-step, how to start using it.

# DatoCMS setup

We provide a template for a dato backend that you can use for this tutorial:

[![Clone DatoCMS project](https://dashboard.datocms.com/clone/button.svg)](https://dashboard.datocms.com/clone?projectId=57262&name=dato-rails
)

Use the button above to setup a first DatoCMS project, proceed to the Settings->API Tokens and fetch your ReadOnly API token that we'll use afterwards.


# Project setup

The gem expects you to have the following:
* a Rails app :smile:
* `turbo`
* `ViewComponents`

Only Rails is an actual requirement, but to use 100% of the features provided by the gem, you'll need also `view_components` and `turbo`.

Given that you are using Rails >= 7, you can follow these commands

```bash
rails new dato-rails-demo --skip-active-record
cd dato-rails-demo
```

Add to your Gemfile:

```ruby
gem 'dotenv-rails', groups: [:development, :test]
gem 'view_component'
gem 'dato-rails', require: 'dato'
```

then run again:

```bash
bundle install
echo "DATO_API_TOKEN=<YOUR_DATO_API_TOKEN>" > .env
```

to install the new libraries and set your Api Token.

Well done. You should be able to simply run `bin/rails s` and access your application.

# Your first query

The provided project contains Homepage. We'll try to fetch it. DatoCMS provides a GraphQL API Explorer that is very useful to generate queries.

We'll start simple with:

```ruby
# app/services/dato/queries.rb

module Dato
  module Queries
    def homepage_query
      GQLi::DSL.query {
        homepage {
          id
        }
      }
    end
  end
end
```

where we define a query to fetch the homepage id.

**You need to restart your server here, since we added a new services folder.**

We should always have tests for our queries. Such a test looks like this:

```ruby
# test/services/dato/queries_test.rb

require "test_helper"

class DatoQueriesTest < ActiveSupport::TestCase
  include Dato::Queries

  test 'homepage_query' do
    client = Dato::Client.new
    response = client.execute(homepage_query)
    assert_not_nil response.data.homepage.id
  end
end
```

If you have a green test, it means your are already successfully fetching your homepage from DatoCMS.

# Render fetched data

We can now generate a controller and a component and we'll render the data that we just fetched.

```bash
rails g controller HomepageController
rails g component Homepage
```

A component is not mandatory, you can also use standard partials, but it will be necessary to benefit of more advanced features like live reloading afterwards.

```ruby
# app/components/homepage_component.rb

class HomepageComponent < ViewComponent::Base
  def initialize(data)
    super
    @data = data
  end
end
```

```erb
# app/components/homepage_component.html.erb

<div>This is the homepage id: <%= @data.homepage.id %></div>
```

```ruby
# app/controllers/homepage_controller.rb
class HomepageController < ApplicationController
  include Dato::Queries

  def show
    client = Dato::Client.new
    response = client.execute(homepage_query)
    render HomepageComponent.new(response.data)
  end
end
```

```ruby
# config/routes.rb

Rails.application.routes.draw do
  root "homepage#show"
end
```

# Structured Text

One of the most important fields that you are going to use on DatoCMS is the [Structured Text](https://www.datocms.com/blog/introducing-structured-text).
You can easily fetch and render it using `dato-rails`.

Update your homepage query:

```ruby
def homepage_query
  GQLi::DSL.query {
    homepage {
      id
      content {
        value
        blocks {
          __typename
          id
          image {
            responsiveImage(imgixParams: {fm: __enum("png")}) {
              ___ Dato::Fragments::ResponsiveImage
            }
          }
        }
      }
    }
  }
end
```

the code above fetches also the `content` field that we use in the homepage and we pre-filled in the example.

Here is how you render a Structured Text field:

```erb
<div>This is the homepage id: <%=@data.homepage.id %></div>
<%= render Dato::StructuredText.new(@data.homepage.content)  %>
```

The library provides you a component that you can use to render already everything. You will now see the following:

![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/96lfuy04z3a2dzgoszlm.png)

# Custom blocks

In the example above, you see that a block was defined in the blocks library of the example. Such blocks are created by you, so the library cannot provide a component to render them, but you need to create one yourself, with the information available. Read the output of the page for more information and instructions on how to define your component.

We will have:

```erb
# app/components/dato/image_block_record.html.erb

<%= render Dato::ResponsiveImage.new(@node.image.responsiveImage)  %>
```

```ruby
# app/components/dato/image_block_record.rb

module Dato
  class ImageBlockRecord < Dato::Node
  end
end
```

you can now simply reload the page, and your block will be rendered correctly with a [responsive image](https://www.datocms.com/blog/best-way-for-handling-react-images).

# Customizations

Let's start by adding simple.css to our `application.html.erb` header so that it looks better:

```erb
<link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
```

If you want to override how a Structured Text node is rendered you have two possibilities:

**CSS only**
The nodes contain HTML classes that you can use to customize the look and feel of each node by working only with CSS.

```css
.dato-cms-paragraph {
  margin-top: 30px;
}
```

will add 30px margin top to all the paragraphs nodes.

**Override the component**
We cannot unfortunately override [only the template](https://github.com/github/view_component/issues/411) at the moment. So if you want to customize your node further, you'll need to do the following:

1. Define a new component. Let's define a new component for the cite block

```ruby
# app/components/dato/fancy_cite.rb
class Dato::FancyCite < Dato::DastNode
  def initialize(node, root)
    super(node, "blockquote", root)
  end
end
```

```erb
# app/components/dato/fancy_cite.html.erb
<blockquote>
  <% @node.children&.each do |node| %>
    <%= render_node(node) %>
  <% end %>
  <p>
    <cite>– <%= @node.attribution %></cite>
  </p>
</blockquote>
```

```ruby
# config/initializers/dato.rb
Dato::Config.overrides = {
  blockquote: 'Dato::FancyCite'
}.with_indifferent_access
```

Since we added an initializer, restart the server.
This is how you override completely a node.

# Preview mode

When using the [draft/published feature of Dato CMS](https://www.datocms.com/docs/general-concepts/draft-published), you can fetch the draft version of your model when using the client. We will change the controller as follow:

```ruby
client = Dato::Client.new(preview: params[:preview].present?)
```

and enable Draft/Preview for our Homepage model.

Proceed to the Settings of the project, and then models, select the Homepage model, and click Edit Model.

![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/vm4lu8aynneams8nfref.png)


Now you can check how the page looks like when passing the `preview` parameter in the URL and you perform changes on the Homepage. Head to http://localhost:3000?preview=true.

# Real Time Mode

Working on DatoCMS to edit your homepage and going back and forth to your website and hit "refresh" every time, might be tedious and time consuming. Real Time Mode is one of the most interesting features of Dato and you can benefit from it also when using Rails.

The only thing you need to do is to wrap your component into a `Dato::Live` component and mount the routes.

We'll change the controller action as follows:

```ruby
def show
  render Dato::Live.new(HomepageComponent, 
                        homepage_query, 
                        preview: params[:preview].present?,
                        live: params[:live].present?)
end
```

And mount the engine routes:

```ruby
# config/routes.rb

Rails.application.routes.draw do
  root "homepage#show"

  mount Dato::Engine => '/dato'
end
```

Head to your page and add the parameters `?live=true&preview=true` to the URL and enjoy live reloading.

![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/mux698un6zb54119g8n2.gif)
 

