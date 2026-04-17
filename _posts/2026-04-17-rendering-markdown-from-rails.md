---
layout: post
title: "Rendering Markdown from Rails"
date: 2026-04-17
categories: rails
excerpt: "Serving the same URL as HTML to humans and Markdown to LLMs sounds trivial: until Rails' content negotiation gets in the way."
---

LLMs consume Markdown better than HTML. More and more often I find myself wanting the same URL to serve a proper HTML page to a browser and a clean Markdown document to a
crawler or an agent. Rails already has everything for that: `respond_to`, template variants, format-specific views. Or so I thought.

## The obvious setup

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    respond_to do |format|
      format.html
      format.md
    end
  end
end
```

With `show.html.erb` and `show.md.erb` sitting next to each other,
a client sending `Accept: text/markdown` should get the Markdown view. 
In practice, it does not. It gets the HTML one.

## Why Rails picks HTML

Rails iterates over `request.formats` in order and renders the first template it finds.
When a client sends `Accept: text/markdown, text/html;q=0.9`, `request.formats` is built
from that header: `[:md, :html]`. Good. 
But many clients: browsers, `curl` without an explicit `Accept`, agents that forward `*/*`: end up with `:html` first, and Rails never looks for the Markdown template even when one exists.

I opened [rails/rails#56632](https://github.com/rails/rails/pull/56632) to make the lookup smarter, so that a registered Markdown template wins over HTML when the client
explicitly asked for Markdown, regardless of the rest of the `Accept` list.

## The workaround until it lands

Until that change ships you can get the same behaviour with a five-line `before_action`
in `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  before_action :prioritize_markdown_format

  private

  def prioritize_markdown_format
    return unless request.accepts.first&.to_s == "text/markdown"

    request.formats = %i[md html]
  end
end
```

If the client's most-preferred type is `text/markdown`, we rewrite `request.formats` so Rails looks for a `.md` template first and falls back to `.html` when there isn't one.
That fallback matters: it means you can opt individual actions into Markdown by just dropping a `show.md.erb` next to `show.html.erb`, without touching the controller.

## What the Markdown view looks like

Nothing fancy. It's just ERB that happens to emit Markdown:

```erb
# <%= @article.title %>

<%= @article.body %>

---
[All articles](<%= articles_path %>)
```
