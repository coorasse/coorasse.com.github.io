---
layout: post
title: "Handling missing frames in Turbo"
date: 2025-05-28
categories: rails
excerpt: "Some tips on how to handle missing frames with Turbo"
---

When you perform a turbo frame request and the server response doesn't contain a matching `<turbo-frame>` element, it considers this an error. 
By default, Turbo will render:

```html
<strong class="turbo-frame-error">Content missing</strong>
```

into the frame.

In your application you might want a friendlier fallback, like a styled error message, or even a full-page redirect. 

Turbo exposes a `turbo:frame-missing` event so you can override this default behavior. 

Here are some ways to handle missing frames gracefully.

---

## Intercepting `turbo:frame-missing`

Add a global event listener early in your JavaScript bundle:

```js
document.addEventListener("turbo:frame-missing", (event) => {
  // Prevent Turbo from injecting the default "Content missing" message
  event.preventDefault();

  // Replace the frame’s innerHTML with custom content
  event.target.innerHTML = `
    <div class="my-frame-error">
      <h3>Oops—something went wrong.</h3>
      <p>Please try again later or <a href="/">return home</a>.</p>
    </div>`;
});
```

---

## Inspecting the Failed Response

The `turbo:frame-missing` event includes detailed information about the failed fetch via `event.detail.response`:

```js
document.addEventListener("turbo:frame-missing", async (event) => {
  const { response } = event.detail;
  const { statusCode } = response;
  const responseHTML = await fetchResponse.responseHTML;

  // Handle 404s differently from 500s, for example:
  if (statusCode === 404) {
    event.preventDefault();
    event.target.innerHTML = `<div class="not-found">Content not found.</div>`;
  } else if (statusCode >= 500) {
    event.preventDefault();
    event.target.innerHTML = `<div class="server-error">Server error—please try again.</div>`;
  } else { // render the response HTML
    event.detail.render(event.target, new DOMParser().parseFromString(responseHTML, "text/html"));
  }
});
```

This gives you full control to render different content based on HTTP status codes or even parse additional markup from the response.

## Controller-Based Turbo Missing-Frame Handling

Instead of listening for `turbo:frame-missing`, you can rescue errors in your `ApplicationController` and render a partial that matches the missing frame's ID.
Turbo will swap the frame content automatically.

Here is an example to handle a specific error.

1. Rescue in ApplicationController

```ruby
class ApplicationController < ActionController::Base
  rescue_from Net::SSH::AuthenticationFailed, with: :ssh_authentication_failed

  private

  def ssh_authentication_failed
    turbo_error("SSH Authentication failed. Please check your SSH key and try again.", my_redirect_path)
  end

  def turbo_error(message, redirect_path)
    if turbo_frame_request?
      render partial: "shared/turbo_frame_missing", locals: { message: message }
    else
      flash[:error] = message
      redirect_to redirect_path
    end
  end
end
```

2. Create the _turbo_frame_missing Partial

```erb
<!-- app/views/shared/_turbo_frame_missing.html.erb -->
<%= turbo_frame_tag request.headers["Turbo-Frame"] do %>
  <div class="alert alert-danger d-flex align-items-center" role="alert">
    <i class="fas fa-exclamation-circle me-2"></i>
    <div><%= message %></div>
  </div>
<% end %>
```

This partial:

* Uses the Turbo-Frame header to identify which frame to target.
* Wraps your custom error UI inside a `<turbo-frame>` tag with the matching id.
* Ensures Turbo replaces the missing frame content without any extra JavaScript.


## Conclusion
You now have two patterns to handle missing frames in Turbo:

* **Client-Side Override**:
  Listen for `turbo:frame-missing`, prevent default rendering, and inject your UI or parse a JSON/HTML error payload.

* **Controller-Based Rendering**
Rescue exceptions in `ApplicationController`, detect Turbo frame requests, and render a matching `<turbo-frame>` partial, with no extra JavaScript needed.

Choose the approach that best fits your case!
