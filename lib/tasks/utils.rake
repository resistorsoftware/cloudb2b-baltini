require "money/bank/open_exchange_rates_bank"

namespace :cloudb2b do

  desc "Set Exchange Rates"
  task set_rates: :environment do
    oxr = Money::Bank::OpenExchangeRatesBank.new(Money::RatesStore::Memory.new)
    oxr.app_id = ENV.fetch("OPEN_ID_EXCHANGE_RATE_SECRET", "").presence
    oxr.update_rates
    Money.default_bank = oxr
    rates = {}
    ["EUR", "CAD", "GBP", "AUD", "HKD", "SGD"].each do |country|
      rate = Money.default_bank.get_rate(country, "USD")
      puts "Setting Exchange rate for #{country} to: #{rate}"
      rates[country] = rate
    end
    s = Shop.first
    s.exchange_rates = rates
    s.save
  end

  desc "Add a Carrier Service"
  task add_carrier: :environment do
    url = if Rails.env == "development"
      "hotwire-resistor.myshopify.com"
    else
      "cloud-b2b.myshopify.com"
    end
    shop = Shop.find_by(shopify_domain: url)
    raise "No Shop Found! #{url}" if !shop

    shop.with_shopify_session do
      cs = ShopifyAPI::CarrierService.new
      cs.name = "CloudB2B Shipping"
      cs.service_discovery = true
      cs.callback_url = if Rails.env == "development"
        "https://cloudb2b.ngrok.io/shipping"
      else
        "https://cloudb2b-baltini-1e66eb7c91d1.herokuapp.com/shipping"
      end
      cs.save!
      puts "Result of carrier service create: #{cs.inspect}"
    end
  end
end

