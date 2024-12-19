# frozen_string_literal: true

class HomeController < AuthenticatedController
  def index
  end

  def edit
  end

  def create
    rates = current_shop.rates
    rates[params[:settings][:country]] = {
      threshold: params[:settings][:threshold],
      percentage: params[:settings][:percentage]
    }
    current_shop.rates = rates
    current_shop.save!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("rates", partial: "rates") }
    end
  end

  def delete
    Rails.logger.info("Deleting according to code #{params[:code]}")
    rates = current_shop.rates
    rates.delete(params[:code])
    current_shop.rates = rates
    current_shop.save!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("rates", partial: "rates") }
    end
  end

  def update
    settings = params[:settings]
    Rails.logger.info("Settings of note are #{settings["countryCode"]}, #{settings["threshold"]}, #{settings["percentage"]}")
    rates = current_shop.rates
    Rails.logger.info("Threshold: #{rates[settings["countryCode"]]["threshold"]}, #{settings["threshold"]}")
    rates[settings["countryCode"]]["threshold"] = settings["threshold"]
    rates[settings["countryCode"]]["percentage"] = settings["percentage"]
    Rails.logger.info("New Rates! #{rates}")
    current_shop.rates = rates
    current_shop.save!
    head :ok
  end
end
