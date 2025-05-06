---
layout: post
title: "To counter cache or not"
date: 2025-05-06
categories: rails
excerpt: "Rails counter_cache are great but they serve one purpose, and you should always remember that they are cached values"
---

I recently discussed on the implementation and use of counter cache. The case is simple and usual:

```ruby
class Deal
  has_many :coupons
end

class Coupon
  belongs_to :deal
end
```

Since we display a list of Deals and their associated coupons, we introduced a counter_cache to remove N+1 queries from the following view:

```erb
<% @deals.each do |deal| %>
  <div>
    <%= deal.coupons.count %>
  </div>
<% end %>
```

so by introducing a counter cache we can now write:

```ruby
class Coupon
  belongs_to :deal, counter_cache: true
end
```

```erb
<% @deals.each do |deal| %>
  <div>
    <%= deal.coupons_count %>
  </div>
<% end %>
```

and our N+1 query is gone.

But we should always be aware that this is a "cache", and if you programmed for more than 15 minutes in your life, you know the golden rule:

> CACHE = BUGS

So what if your coupons are a limited resource? What if there are money attached to those coupons? Do you still want to rely on a cached value?
The answer is **NO**.

Given the following code:

```ruby
class Deal
  def claim
    with_lock do
      available = initial_quantity - coupons.count
      coupons.create!(user:) if available > 0
    end
  end
end
```

always perform a real count on the resource and do not rely on the cached value. In this case, use `coupons.count` and not `coupons_count`.

This of course **must** come with a test. Here is an example:

```ruby
describe "#claim" do
  context "when the counter_cache is not up-to-date" do
    let(:deal) { create(:deal, initial_quantity: 2) }
    before do
      create_list(:coupon, 2, deal: deal)
      Coupon.delete_all # this is a real-world scenario. We often do data-migration or use SQL instructions directly
    end

    it "allows claiming nevertheless" do
      expect(deal.coupons.count).to eq(0)
      expect(deal.available_quantity).to eq(0) # wrong!
      deal.claim
      expect(deal.coupons.count).to eq(1)
    end
  end 
end
```

If you are not a big fan of cached value and Rails cache columns, you can also have a look at https://github.com/djezzzl/n1_loader.

The code would look as follow in our case:

```ruby
class Deal
  n1_optimized :coupons_count do |deals|
    total_per_deal = Coupon.group(:deal_id).where(deal: deals).count.tap { |h| h.default = 0 }
    deals.each do |deal|
      total = total_per_deal[deal.id]
      fulfill(deal, total)
    end
  end
end
```

and you can use:

```erb
<% @deals.each do |deal| %>
  <div>
    <%= deal.coupons_count %>
  </div>
<% end %>
```

Now, this solution has the advantage to always use the real count. 
There's no cache involved and therefore the value is guaranteed to always be the real count.

The disadvantage is, of course, the additional query, which might more expensive and you need a bit more code.

Next time you need to solve an N+1 problem, you might consider one of these two options.
 
