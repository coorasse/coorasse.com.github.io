---
layout: post
title: "Let's refactor this together"
date: 2025-04-12 15:28:03 +0200
categories: rails
---

I recently found my self reviewing the following Rails code and I want to show how this code can be refactored to be more elegant:

{% highlight ruby %}

# models/deal.rb

class Deal
  def percentage_of_quantity(amount)
    (amount.to_f / initial_quantity.to_f * 100.0).floor.to_s + "%"
  end
end
{% endhighlight %}

{% highlight erb %}
<!-- show.html.erb -->

<%= @deal.percentage_of_quantity(@deal.coupons.count) %>
<%= @deal.percentage_of_quantity(@deal.redeemed_coupons.count) %>
<%= @deal.percentage_of_quantity(@deal.expired_coupons.count) %>

{% endhighlight %}

There are multiple things that feel wrong, and I want to explain what and why.

## Move presentation logic to the view layer

{% highlight ruby %}
def percentage_of_quantity(amount)
  (amount.to_f / initial_quantity.to_f * 100.0).floor.to_s + "%"
end
{% endhighlight %}

incorporates a `+ "%"` that is responsibility of the view layer. How to show a percentage, is a responsibility of the
view, not of the model.
Rails provides an helper method for that called [
`number_to_percentage`](https://api.rubyonrails.org/classes/ActiveSupport/NumberHelper.html#method-i-number_to_percentage)
which should be used to convert a number in the desired format on the view layer.

The refactored code looks like:

{% highlight ruby %}
def percentage_of_quantity(amount)
  (amount.to_f / initial_quantity.to_f * 100.0).floor
end
{% endhighlight %}

{% highlight erb %}
<!-- show.html.erb -->

<%= number_to_percentage(@deal.percentage_of_quantity(@deal.coupons.count)) %>
<%= number_to_percentage(@deal.percentage_of_quantity(@deal.redeemed_coupons.count)) %>
<%= number_to_percentage(@deal.percentage_of_quantity(@deal.expired_coupons.count)) %>

{% endhighlight %}

Using this method, will allow us to change the representation of the percentage values using `number_to_percentage`
options.

Look more closely to the method now, and let's have a look at the call to [
`.floor`](https://ruby-doc.org/core-2.6.7/Float.html#method-i-floor).
We want to **represent** the percentage with the largest integer lower or equal to our float. This is again part of the
presentation layer.
`Deal` should return us the percentage value: the fact that we represent it as an integer, it's again a responsibility
of the view layer.

{% highlight ruby %}
def percentage_of_quantity(amount)
  amount.to_f / initial_quantity.to_f * 100.0
end
{% endhighlight %}

{% highlight erb %}
<!-- show.html.erb -->

<%= number_to_percentage(..., precision: 0, round_mode: :down) %>
<%= number_to_percentage(..., precision: 0, round_mode: :down) %>
<%= number_to_percentage(..., precision: 0, round_mode: :down) %>

{% endhighlight %}

Let's take advantage of `number_to_percentage` I18n support so we can simplify again our view and remove the `precision`
and `round_mode` everywhere:

{% highlight yml %}
en:
  number:
    percentage:
      format:
        precision: 0
        round_mode: down
{% endhighlight %}

{% highlight ruby %}
def percentage_of_quantity(amount)
  amount.to_f / initial_quantity.to_f * 100.0
end
{% endhighlight %}

{% highlight erb %}
<!-- show.html.erb -->

<%= number_to_percentage(@deal.percentage_of_quantity(@deal.coupons.count)) %>
<%= number_to_percentage(@deal.percentage_of_quantity(@deal.redeemed_coupons.count)) %>
<%= number_to_percentage(@deal.percentage_of_quantity(@deal.expired_coupons.count)) %>

{% endhighlight %}

## Tell. Don't ask

This code is still smelling, and the reason is that it does not respect
the ["Tell. Don't ask" principle](https://martinfowler.com/bliki/TellDontAsk.html).

Let me recap the most important bits:

> object-orientation is about bundling data with the functions that operate on that data. It reminds us that rather than
> asking an object for data and acting on that data, we should instead tell an object what to do. This encourages to
> move
> behavior into an object to go with the data.
>
> -- <cite>Martin Fowler</cite>

The quote above is the quintessence of
the [ActiveRecord pattern](https://www.martinfowler.com/eaaCatalog/activeRecord.html).

The `Deal` object knows exactly what percentage of coupons have been emitted on the total available quantity, but
nevertheless we are

When we call `@deal.percentage_of_quantity(@deal.coupons.count)` what we really want is to know what is the percentage
of coupons that have been issued on the total available, but instead of just telling the "Deal" what we want, we are
taking part of the responsibility of permising the calculation and decide which fields are involved.

A better approach is to refactor the code as follows:

{% highlight ruby %}

# models/deal.rb

class Deal
  def issued_coupons_percentage = percentage_of_initial_quantity(coupons.count)
  def redeemed_coupons_percentage = percentage_of_initial_quantity(redeemed_coupons.count)
  def expired_coupons_percentage = percentage_of_initial_quantity(expired_coupons.count)

  private
    def percentage_of_initial_quantity(amount) = amount.to_f / initial_quantity.to_f * 100.0
end
{% endhighlight %}

{% highlight erb %}
<!-- show.html.erb -->

<%= number_to_percentage @deal.issued_coupons_percentage %>
<%= number_to_percentage @deal.redeemed_coupons_percentage %>
<%= number_to_percentage @deal.expired_coupons_percentage %>

{% endhighlight %}

We have now a perfect[^1] solution that accomplishes the following:
* clear separation of presentation layer and business logic
* Business logic is moved into the Deal model, and it respects the "Tell. Don't ask principle"
* Law Of Demeter is also respected
* We expose only what is needed. Note how we made the  `percentage_of_quantity` method private!

A final note on readability: "Code is written once but read many times". 
When we read or view code it's not immediately clear what information we are displaying (`issued_coupons_percentage`), and how we want to display it (`number_to_percentage` helper).
We removed everything else.
Also the small renaming of `percentage_of_initial_quantity` instead of `percentage_of_quantity` removes confusion from future readers: the Deal has an `initial_quantity`, what is now `quantity`?
This small details are very important for future readers.

[^1]: Can code really be perfect?

