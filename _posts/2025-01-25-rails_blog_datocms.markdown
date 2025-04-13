---
layout: post
title: "Rails Blog with DatoCMS"
date: 2025-01-25 12:00:00 +0100
categories: rails
excerpt: "If you ever thought about building a Blog in Ruby On Rails and use a Headless CMS, I want to show you how we did that for our Blog on renuo.ch"
---

DatoCMS is an amazing Headless CMS. 
I wrote already in the past [how to integrate it into your Ruby On Rails application](https://dev.to/renuo/datocms-with-ruby-on-rails-3ae5), 
and today I want to show you how to implement a real blog mimicking what is already done for other frameworks, for example [nextjs](https://nextjs-demo-bay.vercel.app/).

## Create a Dato project

You can [clone the existing template](https://www.datocms.com/marketplace/starters/nextjs-template-blog) for this tutorial. 
This template will setup all the models you need on Dato and create some blog posts.

Head to the Project Settings and save your GraphQL API Token for later.

## Setup Rails App

Our Rails 8 application is set up using a simple `rails new dato-blog` command. 
In a few seconds you'll have your Rails 8 app ready and you can start it with `bin/dev`.

You can now include the [`dato-rails`](https://github.com/renuo/dato-rails) gem in your Gemfile and set the API token in your credentials as `dato.api_token`.

![Example of secrets on Rails credentials](/assets/rails_blog_datocms/secrets.png)

You can finally write a simple test to verify that the installation is successful:

```ruby
# test/models/dato_queries_test.rb

require 'test_helper'

class DatoQueriesTest < ActiveSupport::TestCase
  def test_homepage_query
    homepage_query =
      GQLi::DSL.query do
        allPosts {
          title
        }
      end

    client = Dato::Client.new
    response = client.execute(homepage_query)
    assert_not_empty response.data.allPosts
  end
end
```

What this test does, is to run a GraphQL Query and test the connection to DatoCMS.

You can always head to the CDA Playground in DatoCMS to create new queries.

## Simple styling
Let's also set up Bootstrap for some simple, default styles. The Dato Rails integration does not provide any CSS, so you can easily integrate your favorite CSS Framework.

You can add Bootstrap in your `application.html.erb` to have some styling:

```erb
# app/views/layouts/application.html.erb

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">


<body>
  <div class="container">
    <%= yield %>
  </div>
</body>
```

## Blog Post Page

Head to the [Blog Example](https://nextjs-demo-bay.vercel.app/) to see a Preview of the website we want to build. We will start with the single Blog Post page and then we will implement the Homepage.

The first thing you need is the query to fetch a single blog post.

You can create a `models/dato_queries.rb` file to include your queries.

```ruby
# models/dato_queries.rb

module DatoQueries
  def homepage_query
    GQLi::DSL.query do
      allPosts {
        title        
      }
    end
  end

  def blog_post_query(slug)
    GQLi::DSL.query do
      post(filter: { slug: { eq: slug } }) {
        title
        slug
        date
        author {
          name
        }
      }
    end  
  end
end
```

Before digging further, let's test it:

```ruby
# test/models/dato_queries_test.rb

require 'test_helper'

class DatoQueriesTest < ActiveSupport::TestCase
  include DatoQueries

  def test_homepage_query
    client = Dato::Client.new
    response = client.execute(homepage_query)
    assert_not_empty response.data.allPosts
  end

  def test_blog_post_query
    client = Dato::Client.new
    response = client.execute(blog_post_query('mistakes-tourists-make-on-their-first-trip-abroad'))
    assert_not_empty response.data.post.title
  end
end
```

Now that we have the queries, we need to implement the page.

Head to your routes.rb and add

```ruby
resources :blog_posts, only: [:show], param: :slug
```

and our controller will look like this:

```ruby
# app/controllers/blog_posts_controller.rb

class BlogPostsController < ApplicationController
  include DatoQueries

  def show
    response = blog_post_query(params[:slug])
    render BlogPostComponent.new(response.data)
  end
end
```

here is a simple implementation of the BlogPostComponent that renders the blog post.

```ruby
# app/components/blog_post_component.rb

class BlogPostComponent < Dato::BaseComponent
end
```

```erb
# app/components/blog_post_component.html.erb

<h1><%= data.post.title %></h1>
```

You can now head to http://localhost:3000/blog_posts/mistakes-tourists-make-on-their-first-trip-abroad to see your post title.



You now rendered content from DatoCMS into your Rails Application. Let's add the header image now.

The first thing we need to do is to fetch the image from Dato. Our query will become:


```ruby
def blog_post_query(slug)
  GQLi::DSL.query do
    post(filter: { slug: { eq: slug } }) {
      title
      slug
      date
      author {
        name
      }
      coverImage {
        responsiveImage(imgixParams: { fm: :jpg, fit: :crop, w: 2000, h: 1000 }) {
          ___ Dato::Fragments::ResponsiveImage
        }
      }
    }
  end
end
```

`dato-rails` offers a GraphQL fragment to fetch images from DatoCMS in the right format to be displayed. 
[Read more about it on DatoCMS](https://www.datocms.com/blog/best-way-for-handling-react-images#putting-it-all-together-introducing-the-responsiveimage-query). 
We are fetching the coverImage and using the existing ResponsiveImage fragment provided by `dato-rails` to get all the data we need.

With this updated query, we can now display the header image.

```erb
# app/components/blog_post_component.html.erb

<h1><%= data.post.title %></h1>

<div class="d-flex">
  <span class="mr-auto"><%= data.post.author.name %></span>
</div>

<%= render Dato::ResponsiveImage.new(data.post.coverImage.responsiveImage) %>
```

![Result rendered in browser](/assets/rails_blog_datocms/result.png)

From now on, you can look at the [component code](https://github.com/renuo/dato-blog-example/tree/main/app/components) and the query code on the [Github Repository](https://github.com/renuo/dato-blog-example) to see the final version.

## Homepage

Rendering the Homepage has nothing special at this point. You can check the [Github Repo](https://github.com/renuo/dato-blog-example) for the final code, but you basically need a root in your routes.rb, a controller, a new component, and a query.

```ruby
# app/config/routes.rb

root "homepage#show"
```

```ruby
# app/controllers/homepage_controller.rb

class HomepageController < ApplicationController
  include DatoQueries

  def show
    render HomepageComponent.new(homepage_query)
  end
end
```

## Preview mode

We have the following concepts:
* graphQL Query: logic to fetch data
* controller: responsible for choosing a query and using it to renderer a component
* component: responsible for the view logic.

DatoCMS offers a preview mode. You are responsible of deciding how and when a preview is displayed, this can be enabled for specific users of your application, or with a secret token in the URL. In our example we will use the preview parameter of the URL.

You can change the BlogPostsController as follows:

```ruby
render Dato::Wrapper.new(BlogPostComponent, blog_post_query(params[:slug]), preview: params[:preview])
```

to enable preview rendering when the preview parameter is passed.

Head to http://localhost:3000/blog_posts/mistakes-tourists-make-on-their-first-trip-abroad?preview=true

and you will see the Draft version of your Blog Post. You can edit it on DatoCMS and see the new version until you publish it.

## Live mode

The second, interesting feature is live mode so you don't need to manually refresh your Browser window anymore. Similar to what we did before change your controller in:

```ruby
render Dato::Wrapper.new(BlogPostComponent, blog_post_query(params[:slug]), preview: params[:preview], live: params[:live])
```

to enable preview rendering when the preview parameter is passed.

Head to http://localhost:3000/blog_posts/mistakes-tourists-make-on-their-first-trip-abroad?preview=true&live=true

## Caching

This is a very important topic since we don't want to hit DatoCMS every time we render a Blog Post page. The `Dato::Wrapper` component that you used previously will take care also of this and will cache the entire rendered component so that subsequent calls to the same page will be instant and will not require invoking DatoCMS again.

There are cases where you might not be using `Dato::Wrapper`, for such cases you can use the method `data = execute_dato_query(your_query)` to cache your query results automatically or directly `Dato::Cache.fetch { ... }` method similar to how you would use the Rails cache.

You should then configure Dato to automatically expire the cache when you publish your changes. [Read more about it the README](https://github.com/renuo/dato-rails?tab=readme-ov-file#publish-endpoint).
