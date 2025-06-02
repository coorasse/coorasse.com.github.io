---
layout: post
title: "Test downloaded files with RSpec and System Tests"
date: 2020-06-18
categories: rails
excerpt: "How to test files download in your Capybara tests"
---

## Scenario

You have a download button, that downloads a dynamically generated file, and you want to test that the file is downloaded correctly. 
A request test is not sufficient, because the file changes, depending on the actions performed by the user in previous steps, so you want to test that in a system test.

## Solution

The solution is based on the fact that you are using `rspec`, `selenium-webdriver` and Chrome to run you tests.

First of all, you need a custom driver, that is able to manage downloads. You can add the following to the `rails_helper`:

```ruby
Capybara.register_driver :selenium_chrome_headless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args << '--headless'
    opts.args << '--disable-site-isolation-trials'
  end
  browser_options.add_preference(:download, prompt_for_download: false, default_directory: DownloadHelpers::PATH.to_s)

  browser_options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end
```

and implement a `DownloadHelper` module:

```ruby
module DownloadHelpers
  TIMEOUT = 10
  PATH = Rails.root.join('tmp/downloads')

  def downloads
    Dir[PATH.join('*')]
  end

  def download
    downloads.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.1 until downloaded?
    end
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def downloading?
    downloads.grep(/\.crdownload$/).any?
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end
end
```

Now, you have a driver, that is able to manage downloads. Use it and clean the downloads before and after each test. 
So, again, in the `rails_helper.rb`:

```ruby
config.before(:each, type: :system, js: true) do
  clear_downloads
  driven_by :selenium_chrome_headless
end

config.after(:each, type: :system, js: true) do
  clear_downloads
end
```

and here is a small example of usage in a system test:

```ruby
visit the_page_with_download_button_path
find("Download as PDF").click
wait_for_download
expect(downloads.length).to eq(1)
expect(download).to match(/.*\.pdf/)
```

If you want, the driver above is available as `selenium_chrome_with_downloads` and 
`selenium_chrome_headless_with_downloads` in the [so_many_devices](https://github.com/renuo/so_many_devices#chrome-with-downloads-capabilities) gem, 
kindly offered by [Renuo](https://renuo.ch). 
