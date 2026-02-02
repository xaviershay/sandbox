#!/usr/bin/env ruby
# frozen_string_literal: true

# Kindle Bulk Downloader
# Automates selecting all books on each page of "Manage Your Content and Devices"
# and delivering them to a specific Kindle device.
#
# Prerequisites:
#   gem install capybara selenium-webdriver
#
# Usage:
#   ruby kindle_bulk_download.rb
#
# Notes:
#   - The script opens a visible Chrome browser so you can log in manually.
#   - After login, press Enter in the terminal to start automation.
#   - Adjust DEVICE_NAME below to match your Kindle's name exactly.

require "capybara"
require "capybara/dsl"
require "selenium-webdriver"

DEVICE_NAME = "Xavier's Oasis"
AMAZON_CONTENT_URL = "https://www.amazon.com/hz/mycd/digital-console/contentlist/booksAll/dateDsc"

# How long to wait for elements (seconds)
MAX_WAIT = 15
# Pause between actions to avoid hammering Amazon
ACTION_DELAY = 1.5
# Pause after delivering a page of books (let Amazon process)
DELIVERY_DELAY = 5

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--start-maximized")
  options.add_argument("--disable-blink-features=AutomationControlled")
  # Keeps the browser open if the script crashes
  options.add_argument("--detach")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :chrome
Capybara.default_max_wait_time = MAX_WAIT
Capybara.app_host = "https://www.amazon.com.au"

class KindleBulkDownloader
  include Capybara::DSL

  def run
    navigate_to_content_page
    wait_for_login
    process_all_pages
  end

  private

  def navigate_to_content_page
    puts "Opening Amazon Manage Your Content and Devices..."
    visit AMAZON_CONTENT_URL
  end

  def wait_for_login
    puts
    puts "=" * 60
    puts "  Please log in to your Amazon account in the browser."
    puts "  Once you can see your list of books, come back here"
    puts "  and press ENTER to start the automation."
    puts "=" * 60
    puts
    $stdin.gets
    puts "Starting automation..."
  end

  def process_all_pages
    page_num = 0

    loop do
      page_num += 1
      puts "\n--- Processing page #{page_num} ---"

      sleep ACTION_DELAY

      unless has_books?
        puts "No books found on this page. We might be done."
        break
      end

      select_all_books
      deliver_selected
      wait_for_delivery_confirmation

      unless go_to_next_page
        puts "\nNo more pages. All done!"
        break
      end
    end

    puts "\n✓ Finished processing #{page_num} page(s)."
    puts "  Leave your Kindle on WiFi and plugged in to receive all the books."
  end

  def has_books?
    page.has_css?("[class*='ContentItem'], [id*='content-item'], .digital-content-row", wait: 5)
  end

  def select_all_books
    puts "  Selecting all books on this page..."

    # Amazon's UI has a "Select All" checkbox at the top of the list
    select_all = find(:css, [
      "input[type='checkbox'][name*='selectAll']",
      "input[type='checkbox'][aria-label*='Select all']",
      ".select-all-checkbox input",
      "[class*='SelectAll'] input[type='checkbox']",
      "thead input[type='checkbox']",
      "#select-all-checkbox",
    ].join(", "), wait: MAX_WAIT)

    select_all.click unless select_all.checked?

    sleep ACTION_DELAY
    puts "  ✓ All books selected."
  end

  def deliver_selected
    puts "  Opening delivery dialog..."

    # Click the "Deliver" button (may be labeled "Deliver" or "Send to device")
    deliver_button = find(:xpath, [
      "//button[contains(., 'Deliver')]",
      "//a[contains(., 'Deliver')]",
      "//span[contains(., 'Deliver')]/ancestor::button",
      "//button[contains(., 'Send to')]",
    ].join(" | "), wait: MAX_WAIT)

    deliver_button.click
    sleep ACTION_DELAY

    select_device
    confirm_delivery
  end

  def select_device
    puts "  Selecting device: #{DEVICE_NAME}..."

    # The device selector is usually a dropdown or radio button list in a modal
    if page.has_select?("device", wait: 3)
      # It's a <select> dropdown
      page.select(DEVICE_NAME, from: "device")
    elsif page.has_css?("select", wait: 3)
      # Find any select that contains our device
      page.all("select").each do |sel|
        if sel.has_text?(DEVICE_NAME)
          sel.select(DEVICE_NAME)
          break
        end
      end
    else
      # It might be a list of clickable items / radio buttons
      find(:xpath, "//*[contains(text(), '#{DEVICE_NAME}')]", wait: MAX_WAIT).click
    end

    sleep ACTION_DELAY
    puts "  ✓ Device selected."
  end

  def confirm_delivery
    puts "  Confirming delivery..."

    confirm = find(:xpath, [
      "//button[contains(., 'Deliver')]",
      "//button[contains(., 'Send')]",
      "//button[contains(., 'Confirm')]",
      "//input[@type='submit' and contains(@value, 'Deliver')]",
    ].join(" | "), wait: MAX_WAIT)

    confirm.click
    puts "  ✓ Delivery confirmed for this page."
  end

  def wait_for_delivery_confirmation
    puts "  Waiting for Amazon to process (#{DELIVERY_DELAY}s)..."
    sleep DELIVERY_DELAY

    # Dismiss any success notification if present
    if page.has_css?("[class*='dismiss'], [class*='close-button']", wait: 2)
      page.find("[class*='dismiss'], [class*='close-button']").click rescue nil
    end
  end

  def go_to_next_page
    puts "  Looking for next page..."

    next_link = begin
      find(:css, [
        "a[class*='next']",
        "a[aria-label*='Next']",
        ".pagination-next a",
        "[class*='Pagination'] a:last-child",
      ].join(", "), wait: 3)
    rescue Capybara::ElementNotFound
      # Try finding by text content
      begin
        find(:xpath, "//a[contains(., 'Next')]", wait: 2)
      rescue Capybara::ElementNotFound
        nil
      end
    end

    if next_link
      next_link.click
      sleep ACTION_DELAY
      puts "  → Moved to next page."
      true
    else
      false
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  puts "Kindle Bulk Downloader"
  puts "=" * 40
  puts "Device target: #{DEVICE_NAME}"
  puts

  downloader = KindleBulkDownloader.new
  downloader.run
end