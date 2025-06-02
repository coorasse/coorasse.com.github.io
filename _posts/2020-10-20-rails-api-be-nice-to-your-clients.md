---
layout: post
title: "Rails API: be nice to your clients"
date: 2020-10-20
categories: rails
excerpt: "Since at [Renuo](https://renuo.ch) we recently worked a lot on implementing APIs for third parties and we received strong compliments, 
I decided to share with you the decisions we took and re-used and refined among three different projects, so you can also be nice to your clients :heart:"
---

Since at [Renuo](https://renuo.ch) we recently worked a lot on implementing APIs for third parties and we received strong compliments and comments like

> Oh! Thank god! Finally a well-made API!

I decided to share with you the decisions we took and re-used and refined among three different projects, so you can also be nice to your clients :heart:


# Errors

## ActiveRecord errors

We read through the [jsonapi standard](https://jsonapi.org/) and took out what we consider are the good parts, and removed everything that we didn't need.

That's the structure of our errors when we return them:

```json
{
  "errors": [
    {
      "pointer": "first_name",
      "code": "blank",
      "detail": "First Name can't be blank"
    },
    {
      "pointer": "last_name",
      "code": "blank",
      "detail": "Last Name can't be blank"
    }
  ]
}
```

This structure has the following advantages:

1. Gives you the possibility to define multiple errors, and not a single one.
1. Each error is structured separately and contains:
* a `pointer` to the place where the error happened,
* a `code`, readable by a machine, that defines a unique kind of error,
* a `detail`, that contains text, easy to read by humans, to understand what is wrong.

These errors have all the characteristics necessary to be easily understood, debugged and solved by your clients.

We even return such errors:

```json
{ "pointer": "gender",
  "code": "inclusion",
  "detail": "Gender is not included in the list. Allowed values: male, female, company, other" }
```

by giving a hint on how to solve the problem in the detail itself.

The controller implementation is as easy as

```ruby
def create
  if @model.save
    # ...
  else
    render json: { errors: ErrorsMapper.call(@model) }, status: :unprocessable_entity
  end
end
```

You can find the implementation of the `ErrorsMapper` in this gist:

{% gist https://gist.github.com/coorasse/ecbc8e3a03de147f58438e6d8d2d3fff %}

## Generic errors

How do we keep the same structure when an unexpected error happens? We use a custom middleware that is configured as exceptions_app in application.rb as follows:

```ruby
# config/application.rb

config.exceptions_app = ->(env) { ActionDispatch::JsonApiPublicExceptions.new(Rails.public_path).call(env) }
```

here is an example implementation of such middleware:

{% gist https://gist.github.com/coorasse/c4b54d201218ab2b6f42ec985490b2d1 %}

it has two characteristics:

1. It hides details in case of 500
1. It shows the content of the attribute `reason` in the Exception, if present, allowing us to define custom errors and returning custom messages.
1. It re-uses the `ErrorsMapper` seen above to keep the same errors structure.

This is an example of error:

```json
{
  "errors": [
    {
      "status": 500,
      "code": "internal_server_error",
      "detail": "An internal error occurred. We have been notified and we will tackle the problem as soon as possible."
    }
  ]
}
```

## Custom errors

When we need to display a custom error, we can now rely on Rails `exceptions_app` configuration. If, for example, we want to show an error when the provided api key is missing or wrong we define our custom Exception:

```ruby
class UnauthorizedError < StandardError
  attr_accessor :reason

  def initialize(reason = nil)
    @reason = reason
  end
end
```

and we instruct Rails on how to treat this exception:


```ruby
# config/application.rb

config.action_dispatch.rescue_responses.merge!(
      'UnauthorizedError' => :unauthorized
)
```

we can then raise an Exception and specify also the reason why we raised it:

```ruby
raise UnauthorizedError, :missing_api_key if api_key.blank?
```

or

```ruby
raise UnauthorizedError, :wrong_api_key if request.headers['Api-Key'] != ENV['API_KEY']
```

That's all regarding the errors part. Let's now save some of our clients time :wink:

# fresh_when

I won't go deep in this blog post regarding the usage of `fresh_when`, since you can read everything about it [in the documentation](https://apidock.com/rails/ActionController/ConditionalGet/fresh_when)

I encourage you to use it when possible but do not abuse it and be careful. If, for example, in the response, you return nested resources, you should keep this in consideration when implementing the `fresh_when`. As always: caching is hard and adds complexity to the system. Do it wisely and document it.

# Swagger

Provide a nice and up-to-date swagger documentation of your APIs. The gem [rswag](https://github.com/rswag/rswag) is able to publish a nice, clickable, documentation, generated from the swagger, and also to generate the documentation directly from your tests. Give it a try!

# Strong Parameters

Last suggestion, with also another bit of code that you might re-use. How do you behave when a client sends an unknown parameter? By using StrongParameters you have, in general, two choices:

## You raise an exception

You can configure:

```ruby
config.action_controller.action_on_unpermitted_parameters = :raise
```

and every time you receive an unknown parameter, your application will raise an exception. This is an ok behaviour, but it might not suite all the situations, that's also why the default is the next one:

## You ignore them

By default, unpermitted_parameters are simply ignored and skipped, but this might lead to a problem when the client sends a non-mandatory field and commits a typo. ouch!
You defined the optional field as `zip_code` and they sent `zip`. Since is not mandatory, your API will simply ignore the field and return a nice `201` to the clients, informing them that the record has been saved.

You can be nice to your clients and still return a `201` but also giving them an hint that something might be wrong. We implemented and use the following concern in our controllers:

{% gist https://gist.github.com/coorasse/650f5bc6b87b85066b3af9624e3a0f48 %}

This concern will add a `{"meta": {"hints": [...]}}` part to your response, with the list of attributes sent in the request and not accepted by the API. By default, simply including this concern, you will obtain a response like:

```json
{
 "meta": {
  "hints": ["zip is not a valid parameter"]
 }
}
```

but you can also do one step more and set the list of allowed attributes with:

```ruby

def create
  model.create(model_params)
end

def model_params
 self.permitted_action_params = %i[zip_code first_name last_name]
 params.require(:model_name).permit(permitted_action_params)
end
```

and the error will magically be even more detailed. for the customer:

```json
{
 "meta": {
  "hints": ["zip is not a valid parameter. Did you mean zip_code?"]
 }
}
```

# Versioning

There are different ways how you can version your APIs for breaking changes. The solution we adopt at Renuo is the `Api-Version` header. We went through all other possibilities before deciding that a version header is our first choice. Shortly:
* URL versioning sucks, you need to define all new routes every time you need to release a new version, and do weird customizations to redirect v2 endpoints to v1 controllers if they don't have a v2 implementation. Also, your clients will need to invoke new endpoints 🤮.
* Versioning via query parameter might work but you don't want to mix "meta" parameters with your actual ones.

We usually implement a very easy method that fetches the current wished version by the client:

```ruby
def api_version
  request.headers['Api-Version']&.to_i || 1
end
```

and what might sound weird but is actually really effective, is that at the very beginning, you can simply write something like:

```ruby
def do_something
  if api_version > 1
    do_something_new
  else
   do_something_old
  end
end
```

and you will cover already 80% of your needs.

# Conclusions

I hope the tips above will help you with your work and to implement better APIs. Since it will happen that I am on the client-side, I hope that the developer on the server-side read this blog post.

If you need to implement APIs or need help with your Rails app [get in touch with us at Renuo](https://www.renuo.ch/en/contact). We will be happy to help!
