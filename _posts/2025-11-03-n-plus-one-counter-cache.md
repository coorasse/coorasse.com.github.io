---
layout: post
title: "N+1 queries: counter_cache and the alternative"
date: 2025-11-03
categories: rails
excerpt: "When counter_cache helps with N+1 queries, when it lies to you, and a cache-free alternative worth knowing."
---

N+1 queries are a well-known topic, but there is an alternative to the usual `counter_cache` solution that often surprises people, so it is worth writing down.

## The classic N+1

```ruby
class Deal
  has_many :coupons
end

class Coupon
  belongs_to :deal
end
```

In the view:

```erb
<% @deals.each do |deal| %>
  <div>
    <%= deal.coupons.count %>
  </div>
<% end %>
```

One query for the deals, one extra `COUNT` per deal. The Rails answer is `counter_cache`:

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

The N+1 is gone, and the view reads a column instead of running an aggregate.

## CACHE = BUGS

If you have written software for more than fifteen minutes, you know that any cache will eventually cause bugs. 

`coupons_count` is a column on `deals`, kept in sync by Rails callbacks. 

Anything that bypasses those callbacks (a data migration, a `delete_all`, raw SQL, a `dependent: :delete_all` association) silently corrupts the value.

A slightly wrong number might be fine in some cases, but for anything that triggers a business decision, it is not.

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

Here `coupons.count` is the right call, not `coupons_count`. 
If the cache is stale, you either oversell a limited resource or refuse a valid claim. Both would be serious bugs.

And of course this gets a test:

```ruby
describe "#claim" do
  context "when the counter_cache is not up-to-date" do
    let(:deal) { create(:deal, initial_quantity: 2) }

    before do
      create_list(:coupon, 2, deal: deal)
      Coupon.delete_all # real-world scenario: data-migrations and raw SQL do not update counter_cache
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

## The alternative

Here is the part that often gets overlooked: you do not actually have to choose between "N+1" and "cached column". 

You can compute the real count once, for the whole collection, lazily.

[n1_loader](https://github.com/djezzzl/n1_loader) lets you write it like this:

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

The view is the same as the `counter_cache` version:

```erb
<% @deals.each do |deal| %>
  <div>
    <%= deal.coupons_count %>
  </div>
<% end %>
```

One extra `GROUP BY` query for the whole page, always the real count, no callbacks to maintain, no migrations to backfill, no `reset_counters` task to run when something drifts.

## When to pick which

* `counter_cache` when the value is purely informational, the model graph is simple, and you control every write path.
* A real count (`coupons.count` or `n1_optimized`) when the number drives a decision, when you also write through migrations or raw SQL, or when you simply do not want to think about cache invalidation.

The extra query has a cost. Stale numbers in a `claim` method have a bigger one.
