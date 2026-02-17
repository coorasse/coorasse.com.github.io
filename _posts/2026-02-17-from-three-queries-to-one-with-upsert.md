---
layout: post
title: "From 3 queries to 1 with Rails upsert"
date: 2026-02-17
categories: rails
excerpt: "How I replaced a find_or_create_by + lock + update_columns pattern with a single upsert call, and why it's still atomic"
---

I recently refactored a daily statistics tracking model. The idea is simple: every time a user performs an action (a
view, a download, a click), we record it. One row per resource per day, with multiple counter columns.

The old code looked like this:

```ruby
class DailyStatistic < ApplicationRecord
  def self.track(resource)
    entry = find_or_create_by!(date: Time.zone.today, resource: resource)
    entry.with_lock do
      entry.update_columns(total: entry.total + 1)
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    retry
  end
end
```

This works, but it has performs many queries

For every single tracking event, we perform up to 4 queries:

1. `SELECT` - find the existing record
2. `INSERT` - inserts the record (if needed)
2. `SELECT ... FOR UPDATE` - lock the row
3. `UPDATE` - increment the counter

On top of that, we have a `rescue retry` to handle race conditions on `find_or_create_by!`:
two concurrent requests could both try to create the same row at the same time, one of them would fail, and we'd retry.

## The refactored version

```ruby
class DailyStatistic < ApplicationRecord
  def self.track(resource)
    upsert(
      {
        date: Time.zone.today,
        resource_id: resource.id,
        'total' => 1
      },
      unique_by: %i[date resource_id],
      on_duplicate: Arel.sql("total = daily_statistics.total + 1")
    )
  end
end
```

One method. One query. No locks. No retries.

## The generated SQL

This generates a single SQL statement:

```sql
INSERT INTO daily_statistics (date, resource_id, total)
VALUES ('2026-02-17', 42, 1) ON CONFLICT (date, resource_id)
DO
UPDATE SET total = daily_statistics.total + 1
```

If the row doesn't exist, it inserts it with a value of `1`.
If it does exist (conflict on `date` + `resource_id`), it increments the existing value by `1`.

## The `toral => 1` trick

This value of `1` is only used when **inserting** a new row.
When a row already exists, the `on_duplicate` clause takes over and increments the existing value instead.

## Is it still atomic?

It actually is. In fact, it's **more** atomic than before.

The old code required an explicit `with_lock` (which translates to `SELECT ... FOR UPDATE`) to prevent two concurrent
requests from reading the same value and both writing `total + 1`, effectively losing one increment.

PostgreSQL's `INSERT ... ON CONFLICT ... DO UPDATE` is atomic by design: the database handles the conflict resolution
internally, within a single statement. 
There is no window between the read and the write where another transaction could interfere.

No application-level lock needed. No retry logic needed.

## The unique index

For `upsert` with `unique_by` to work, you need a unique index on the columns that define the conflict:

```ruby
add_index :daily_statistics, [:date, :resource_id], unique: true
```

Without this index, PostgreSQL has no way to detect the conflict and the `ON CONFLICT` clause won't work.

## Summary

The old pattern of `find_or_create_by!` + `with_lock` + `update_columns` is something I see often in Rails codebases. 
It works, but it's more code, more queries, and more things that can go wrong under concurrency.

Rails' `upsert` delegates the hard work to the database, where it belongs. One query, truly atomic, no race conditions.
