---
layout: post
title: "Run your Capybara tests on different devices"
date: 2020-03-02
categories: rails
excerpt: "So many devices!!"
---

## On how many devices are you testing your Rails Application?

As a developer, you work 90% of the time in front of a computer or laptop, but your users access the website from a mobile device.

That's why we started, since some years, to code "mobile-first", having the mobile version of our web applications in mind and as our priority one.

But I realised that all our system tests were running only on the default `selenium_chrome_headless` driver, provided by Capybara.

Not so nice!

What about all the other devices? There are so many devices! And I don't want to configure and maintain these configurations in all our projects. At [Renuo](https://renuo.ch) we maintain about 60 Rails projects. We definitely needed to extract this into a gem.

And here you are [so_many_devices](https://github.com/renuo/so_many_devices)

For now, we published only few devices, but please help us filling the list!

You can now choose between many predefined capybara drivers and simply use them with:

```ruby
config.before(:each, type: :system, js: true) do
    driven_by :iphone_6_7_8
end
```

Enjoy!
