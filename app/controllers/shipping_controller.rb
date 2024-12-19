require "money"

# Some CONSTANTS to clean things up a bit
SPEND_THRESHOLD = 20_000 # $200
SHIPPING_FEE = 1_995 # $19.85

class ShippingController < ApplicationController
  include ShopifyApp::WebhookVerification
  ActionController::Parameters.permit_all_parameters = true
  Money.locale_backend = :i18n
  Money.rounding_mode = BigDecimal::ROUND_HALF_EVEN
  # Country listing
  # Canada: CA
  # United States: US
  # United Arab Emerites: AE
  # Australia: AU
  # Singapore: SG
  # $19.95 for shipping and free shipping for orders above $200.
  # Country listing
  
  def create
    threshold = 0
    percentage = 0.0
    fee = 0
    shop = Shop.find_by(shopify_domain: shop_domain)
    raise "Shop #{shop_domain} not found in DB!" if !shop

    shop.with_shopify_session do
      # pp params
      destination_country = params["rate"]["destination"]["country"]
      # puts "Destination Country is: #{destination_country}"

      # February 2023, return a currency rate that matches the destination country
      currency = params["rate"]["currency"]
      code = IsoCountryCodes.find(destination_country)
      subtotal = checkout_subtotal(items: params["rate"]["items"], currency: params["rate"]["currency"], rates: shop.exchange_rates)
      shipping = (subtotal > SPEND_THRESHOLD) ? 0 : SHIPPING_FEE 
      Rails.logger.debug { "Currency: #{currency}, code: #{code.to_s}, subtotal: #{subtotal}, shipping: #{shipping}" }

      if destination_country == "US"
        threshold = shop.rates[destination_country]["threshold"]
        percentage = shop.rates[destination_country]["percentage"]
        Rails.logger.debug { "US threshold is #{Money.from_cents(threshold * 100, currency).format(thousands_separator: false)}, with a percentage: #{percentage}%" }
        # params[:rate][:items].each do |item|
        # pp item.to_h
        # end
        other_subtotal = 0
        params[:rate][:items].each do |item|
          # item["properties"] _productType contains the word eyewear or glasses if it is interesting, or item["name"]
          # properties = item["properties"] ||= {_productType: ""}
          # regex = /eyewear|glasses/i
          # puts "US item detected: #{item["name"]}, properties: #{properties}"
          # puts "Eyewear product!" if regex.match?(properties["_productType"]) || regex.match?(item["name"]) # quantity purchased times 3% + $42
          # if regex.match?(properties["_productType"]) || regex.match?(item["name"])
          #   # August 2, 2024, Josh said to turn off fees on glasses, so we do that here
          #   # fee += ((item["quantity"].to_i * item["price"].to_i) * 0.03) + (item["quantity"].to_i * 4_200)
          #   # puts "eyeglass fee: #{fee}"
          # else
          other_subtotal += (item["quantity"] * item["price"])
          # end
        end
        # OK, so now we have a fee and we might want to add on to it if the other items added up to more than $800
        puts "Subtotal of items in cart: #{other_subtotal}"
        if other_subtotal > 0
          fee += (other_subtotal >= (threshold * 100)) ? (other_subtotal * (percentage / 100.0)).to_i : 0
          puts "Import Fee for US cart: #{fee}, representing #{percentage}% of subtotal"
        end
        # puts "Fee calculated was #{fee} with shipping #{shipping}"
      elsif shop.rates[destination_country] # we have a rate in the database for this country
        puts "Shop with set rates #{destination_country}: #{shop.rates[destination_country]}, subtotal: #{subtotal}"
        threshold = shop.rates[destination_country]["threshold"].to_i * 100
        percentage = shop.rates[destination_country]["percentage"]
        fee = (subtotal >= threshold) ? (subtotal * (percentage / 100.0)).to_i : 0
        puts "Fee is: #{fee}, with percentage: #{percentage} of subtotal"
      else
        puts "Country with no shop rates detected"
        fee = (subtotal >= 1200) ? (subtotal * (12.0 / 100.0)).to_i : 0
      end

      # New for April 2023
      shipping_subtotal = subtotal
      case destination_country
      when /SG|AU/
        # convert the subtotal to SGD
        currency = code.currency
        puts "Original subtotal: #{subtotal}, exchange rate: #{shop.exchange_rates[currency]}"
        shipping_subtotal = subtotal * (1 / shop.exchange_rates[currency])
        puts "NEW SGD/AUD subtotal: #{shipping_subtotal}"
        shipping = (shipping_subtotal > 30_000) ? 0 : 3_000
        puts "In Singapore or Australia, so Shipping is #{shipping} and currency is #{currency}"
        threshold = shop.rates[destination_country]["threshold"].to_i * 100
        percentage = shop.rates[destination_country]["percentage"]
        fee = (shipping_subtotal >= threshold) ? (shipping_subtotal * (percentage / 100.0)).to_i : 0

      when "HK"
        currency = code.currency
        puts "Original subtotal: #{subtotal}, exchange rate: #{shop.exchange_rates[currency]}"
        shipping_subtotal = subtotal * (1 / shop.exchange_rates[currency])
        puts "NEW HKD subtotal: #{shipping_subtotal}"
        shipping = (shipping_subtotal > 150_000) ? 0 : 16_000
        puts "In Hongkong, so Shipping is #{shipping} and currency is #{currency}"
        threshold = shop.rates[destination_country]["threshold"].to_i * 100
        percentage = shop.rates[destination_country]["percentage"]
        fee = (shipping_subtotal >= threshold) ? (shipping_subtotal * (percentage / 100.0)).to_i : 0
      when /GB|UK/
        currency = code.currency
        puts "Original subtotal: #{subtotal}, exchange rate: #{shop.exchange_rates[currency]}"
        shipping_subtotal = subtotal * (1 / shop.exchange_rates[currency])
        puts "NEW GBP/UK subtotal: #{shipping_subtotal}"
        shipping = (shipping_subtotal > 15_000) ? 0 : 1_500
        puts "In GB/UK, so Shipping is #{shipping} and currency is #{currency}"
        threshold = shop.rates[destination_country]["threshold"].to_i * 100
        percentage = shop.rates[destination_country]["percentage"]
        fee = (shipping_subtotal >= threshold) ? (shipping_subtotal * (percentage / 100.0)).to_i : 0
      when "CA"
        currency = code.currency
        puts "Original subtotal: #{subtotal}, exchange rate: #{shop.exchange_rates[currency]}"
        shipping_subtotal = subtotal * (1 / shop.exchange_rates[currency])
        puts "NEW CAD subtotal: #{shipping_subtotal}"
        shipping = (shipping_subtotal > 25_000) ? 0 : 2_500
        puts "In Canadian currency: subtotal is #{shipping_subtotal}, shipping: #{shipping}"
        threshold = shop.rates[destination_country]["threshold"].to_i * 100
        percentage = shop.rates[destination_country]["percentage"]
        fee = (shipping_subtotal >= threshold) ? (shipping_subtotal * (percentage / 100.0)).to_i : 0
        puts "Fee calculated was #{fee} with shipping #{shipping}"
      end


      # Main differences as specified from Baltini
      # International Shipping (3-5 Business Days) Shipping & Import Duties Included 
      # to
      # Standard International Shipping (4-6 Business Days) Shipping & Import Duties Included
      # and
      # DHL Express International Shipping (2-4 Business Days) Import Duties & Tax Included
      # to
      # Express International Shipping (3-5 Business Days) Import Duties & Tax Included
      
      shipping_amount = Money.from_cents(shipping, currency).format(thousands_separator: false)
      description = if fee > 0
        puts "Final description amount: #{Money.from_cents(fee, currency).format(thousands_separator: false)}"
        "#{shipping_amount} Shipping, #{Money.from_cents(fee, currency).format(thousands_separator: false)} Import Duty and Taxes"
      else
        "No Duty or Tax due"
      end

      rates = [{
        service_name: "Standard International Shipping (4-6 Business Days) Shipping and Import Duties Included",
        service_code: "Standard",
        total_price: fee + shipping,
        description: description,
        currency: currency,
        min_delivery_date: "",
        max_delivery_date: ""
      }]
      if destination_country == "US"
        puts "SUBTOTAL ON US: #{subtotal}"
        shipping_amount = Money.from_cents((subtotal > 20_000) ? 2_000 : 3_000, currency).format(thousands_separator: false)
        total_price = if subtotal > 20_000
          fee + 2_000
        else
          fee + 3_000
        end
        rates.prepend({
          service_name: "Express International Shipping (3-5 Business Days) Import Duties and Tax Included",
          service_code: "Express",
          total_price: total_price,
          description: "#{shipping_amount} Shipping, #{Money.from_cents(fee, currency).format(thousands_separator: false)} Import Duty and Taxes",
          currency: params["rate"]["currency"],
          min_delivery_date: "",
          max_delivery_date: ""
        })
      end

      # rates = [
      #   {
      #       service_name: "Nerd Beans 1", 
      #       service_code: "s1_1", 
      #       total_price: 10000, 
      #       description: "Nerd Beans 1 ships beans",
      #       currency: "USD", 
      #       min_delivery_date: "",
      #       max_delivery_date:""
      #   }, {
      #       service_name: "Nerd Beans 2", 
      #       service_code: "s2_2",
      #       total_price: 12000,
      #       description: "Nerd beans 2 ships beans",
      #       currency: "USD",
      #       min_delivery_date: "",
      #       max_delivery_date: ""
      #   }
      # ]
      pp "Rates: #{rates}"
      render json: {rates: rates}
    end
  end

  private

  def checkout_subtotal(items:, currency:, rates:)
    items.inject(0) do |result, el|
      price = if currency == "USD"
        el["price"].to_i
      elsif ["HKD", "SGD", "AUD", "CAD", "GBP", "EUR"].include?(currency)
        # el["price"].to_i * (1 / shop.exchange_rates[currency])
        el["price"].to_i
      end
      result += price * el["quantity"].to_i
      result
    end
  end
end

