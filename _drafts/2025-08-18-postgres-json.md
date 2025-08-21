# Postgres JSON for Rails developers

## Rename column in JSON column

Given the following structure:

```ruby
# deliver_address jsonb column in the table users
{ "first_name": "John", "last_name": "Doe", "zip": "12345" }
```

we want to rename `zip` to `zip_code`. You can do it with the following migration:

```ruby
execute <<-SQL
  UPDATE users
  SET deliver_address = jsonb_set(deliver_address, '{zip_code}', deliver_address->'zip', true) - 'zip'
  WHERE deliver_address ? 'zip';
SQL
```

If the column contains an array:

```ruby
# deliver_addresses jsonb column in the table users
[{ "first_name": "John", "last_name": "Doe", "zip": "12345" },
 { "first_name": "John", "last_name": "Jack", "zip": "67890" }]
```

you can use the following migration:

```ruby
execute <<-SQL
    ain
SQL
```
