---
layout: post
title: "Strip your parameters"
date: 2020-07-16
categories: rails
excerpt: ""
---

Given a `User` model with first and last name, and a form to submit the data and create a `User`, the client adds some trailing and leading whitespaces in the field inputs and submits the following:

```json
{ 
  "user": {
    "first_name": " Luke",
    "last_name": "Skywalker "
  }
}
```

what is persisted on the database?

...

...

...

...


ActiveRecord takes care of it for us, and will strip automatically the whitespaces and persist "Luke" as first_name and "Skywalker" as last_name, without whitespaces.

In my 6 years working with Rails, I never had to check for leading and trailing whitespaces and never had to even think about it. Until yesterday.

## The case for a search form

When you implement a search form, remember that your customers will expect to find Luke Skywalker, even if they type "Luke " in the search field (with whitespace, by mistake or because they copy-pasted it).

Apart from special cases, there's no discussion that this should happen, your client doesn't need to specify it, and you, as a good developer, should think about it and strip your search parameters.

From now on, when you implement a search form, remember to strip your params. Is easy as:

```ruby
def search_params
  params
    .require(:search)
    .permit(:first_name, :last_name)
    .each_value { |value| value.try(:strip!) }
end
```

