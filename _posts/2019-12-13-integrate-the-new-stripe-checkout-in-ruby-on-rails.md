---
layout: post
title: "Integrate the new Stripe Checkout in Ruby on Rails."
date: 2019-12-13
categories: rails
excerpt: "Are you ready for Strong Customer Authentication?"
---

Are you ready for Strong Customer Authentication?

Since April 2019, Stripe provides a new Checkout service. Let's see how to integrate it step by step. I'll show you how to integrate the [new Stripe Checkout service](https://stripe.com/docs/payments/checkout) into your Rails application. This service allows us to seamlessly integrate a Stripe Checkout form, conform to the new [Strong Customer Authentication](https://stripe.com/docs/strong-customer-authentication) EU regulation.

As always, the Stripe documentation is great, but it took me a bit to understand what was the right approach for my situation. You can re-use this tutorial in any new Rails Application that sells a product. I'll not go into implementation details, but I'll simply suppose you know Rails and you know how to run a migration and manage your models. I'll just cover the parts to connect your system with Stripe.

# Basic setup

## Create Stripe Account and Product

Please refer to the good Stripe documentation to create an account and a product, your clients can subscribe to. You should end up with something like this:
![An example product with two plans: professional and enterprise](https://thepracticaldev.s3.amazonaws.com/i/u6f95x8zhh3526j4z9jc.png)
*An example product with two plans: professional and enterprise.*

## User and Subscription

These are the two models we will use in our system. They must have the following fields:

```ruby
create_table "users" do |t|
    t.string "email", null: false
    t.string "stripe_id"
end

create_table "subscriptions" do |t|
    t.string "plan_id"
    t.integer "user_id"
    t.boolean "active", default: true
    t.datetime "current_period_ends_at"
    t.string "stripe_id"
end
```
Both have a reference to their Stripe counterpart and a `User` has_one `Subscription`.


# Proceed to Checkout

When a customer subscribes to a plan, a Subscription gets created. Since we need to associate the Subscription to an existing User, we have to use the [client-server integration](https://stripe.com/docs/payments/checkout/subscriptions/starting), where the Checkout Session is created server-side.
Let's start by creating the controller:

```ruby
class Stripe::CheckoutsController < ApplicationController
  def new
    session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        subscription_data: {
            items: [{ plan: params[:plan] }],
        },
        customer: current_user.stripe_id,
        client_reference_id: current_user.id,
        success_url: create_checkout_url(session_id: '{CHECKOUT_SESSION_ID}'),
        cancel_url: root_url,
    )

    render json: { session_id: session.id }
  end
end
```

and add the routes:

```ruby
namespace :stripe do
  resources :checkouts
  post 'checkout/webhook', to: "checkouts#webhook"
end

resources :subscriptions
```

This controller initialises a Checkout Session for a given plan and defines the two URLs that will be invoked for a successful subscription or a failed one. In case of success, we go on the create action, otherwise we simply go to the root url. You can customise that later.

For now, we will focus on returning a JSON with the session_id that we need.

The second step is to create a subscribe button on our pricing page. Please take inspiration by this simple Javascript example.

Given this button:

```html
<a data-subscribe="professional" href="#">Sign Up</a>
```

we can define this Javascript to implement a checkout:

```js
document
  .querySelector('[data-subscribe]')
  .addEventListener('click', (event) => {
    fetch(`/subscriptions/new?plan=${event.currentTarget.dataset.subscribe}`)
    .then(response => response.json())
    .then((json) => {
      var stripe = Stripe('<YOUR_STRIPE_PUBLIC_KEY');
      stripe.redirectToCheckout({
        sessionId: json.session_id
      })
    .then(function (result) {
    });
  });
  event.returnValue = false;
});
```

once clicked, the button starts a request to the server to generate a session for the selected plan. The session id is then returned to the browser that redirects to the checkout window offered by Stripe.


# Configuring a webhook

We cannot just rely on a call to the success_url we defined above. The user might close the browser before this page is called or the connection might drop, leaving you with a paying customer without an account. In order to manage this case, we will integrate a Webhook, that we are sure will be called, and that will manage the correct user registration. 


## Create a webhook on Stripe

You can create a webhook for the checkout event from the Stripe Dashboard or by using APIs. Our Webhook will be triggered for a `checkout.session.completed` event and will perform a call to `https://yourapp.com/stripe/checkout/webhook`. Remember to add this webhook to both your test and live environment in Stripe.

## Create a controller action

For this example, we will keep it simple, and imagine that our User is already logged in when subscribing. Your controller action will look like:

```ruby
def webhook
  sig_header = request.env['HTTP_STRIPE_SIGNATURE']

  begin
    event = Stripe::Webhook.construct_event(request.body.read, sig_header, ENV['STRIPE_ENDPOINT_SECRET'])
  rescue JSON::ParserError
    return head :bad_request
  rescue Stripe::SignatureVerificationError
    return head :bad_request
  end

  webhook_checkout_session_completed(event) if event['type'] == 'checkout.session.completed'

  head :ok
end

private 

def build_subscription(stripe_subscription)
    Subscription.new(plan_id: stripe_subscription.plan.id,
                     stripe_id: stripe_subscription.id,
                     current_period_ends_at: Time.zone.at(stripe_subscription.current_period_end))
end

def webhook_checkout_session_completed(event)
  object = event['data']['object']
  customer = Stripe::Customer.retrieve(object['customer'])
  stripe_subscription = Stripe::Subscription.retrieve(object['subscription'])
  subscription = build_subscription(stripe_subscription)
  user = User.find_by(id: object['client_reference_id'])
  user.subscription.interrupt if user.subscription.present?
  user.update!(stripe_id: customer.id, subscription: subscription)
end
```


Now, you can install the [Stripe CLI](https://stripe.com/docs/stripe-cli) and run the following command, that will forward the webhooks calls to your local environment.

```sh
stripe listen - forward-to localhost:3000/stripe/checkout/webhook
```

This command will intercept the webhooks and print a webhook signing secret that you should set as `STRIPE_ENDPOINT_SECRET` env variable and restart the server.

# Success endpoint

When the user finishes the payment process, will be redirected to the success_url. In this `create` action we just set a flash message and redirect to the root_url


```ruby
# stripe/checkouts_controller.rb
def create
  flash[:success] = "You subscribed to our plan!"
  redirect_to root_path
end
```

# Customizing the checkout form

Stripe gives you the possibility to customize the new Checkout form with a certain colours and a logo. You can proceed in your [Branding Settings](https://dashboard.stripe.com/account/branding) to start customizing the form.

# Upgrade the plan

The procedure you just implemented can be re-used to Upgrade the plan to a different one. The Stripe Session Checkout will take care of it for you.

# Interrupt a subscription

Your controller should implement the following:

```ruby
# subscriptions_controller.rb
def interrupt
  current_user.subscription.interrupt
end

# models/subscription.rb
def interrupt
  Stripe::Subscription.delete(stripe_id)
  self.active = false
  save
end
```

# Invoices

Recurring payments and invoice and entirely managed by Stripe. You can supply a link to your customers to download the invoices through something like this:

```ruby
Stripe::Invoice.list(limit: 3, customer: stripe_id).first.invoice_pdf
```

# Edit payment information

[Stripe takes care of many notifications](https://dashboard.stripe.com/account/billing/automatic) to your customers for you. When the customer credit card is expiring or is already expired you should allow them to edit their card details. Following the first example we need an action that looks like the following:

```ruby
def edit
  session = Stripe::Checkout::Session.create(
    payment_method_types: ['card'],
    mode: 'setup',
    setup_intent_data: {
      metadata: {
        customer_id: current_user.stripe_id,
         subscription_id: current_user.subscription.stripe_id,
      },
    },
    customer_email: current_user.email,
    success_url: CGI.unescape(subscription_url(session_id: '{CHECKOUT_SESSION_ID}')),
    cancel_url: subscription_url
  )

  render json: { session_id: session.id }
end
```

and a button that, once clicked, executes the following Javascript code:

```javascript
fetch('/checkout/edit')
      .then(response => response.json())
      .then((json) => {
        Stripe(YOUR_STRIPE_ID).redirectToCheckout({sessionId: json.session_id})
          .then(function (result) {
          });
      });
```

# Recurring payment webhook

Every time the subscription is renewed, and Stripe charges the customer, you want to be notified in order to keep your customer subscription active. We will approach this by implementing a scheduled task that will run every night and check expiring subscriptions.
