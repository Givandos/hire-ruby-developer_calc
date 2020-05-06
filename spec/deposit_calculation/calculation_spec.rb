# frozen_string_literal: true

require "./deposit_calculation/calculation"
require "rack/test"
require "./spec/spec_helper"
require "json"

describe "Calculation service" do
  include Rack::Test::Methods

  let(:params) do
    { amount: 1000,
      rate: "15",
      currency: "uah",
      start_date: (Time.now + 1).to_s,
      duration_period: "month",
      deposit_duration: 12,
      capital: "monthly" }
  end
  let(:calculation) { Calculation.new(stringify_params) }
  let(:default_expected_interest) { 158.77 }

  it "exception if without params" do
    expect { Calculation.new(nil) }.to raise_error(ArgumentError)
    expect { Calculation.new({}) }.to raise_error(ArgumentError)
  end

  it "correct attributes after initialize" do
    expect(calculation.result).to be_a Array
    expect(calculation.result).to be_empty

    expect(calculation.params).to be_a Hash
    expected_params = params.transform_keys!(&:to_sym)
    expect(calculation.params.keys).to match_array expected_params.keys

    expect(calculation.errors).to be_a Array
    expect(calculation.errors).to be_empty
  end

  it "with valid params" do
    calculation.perform
    expect(calculation.result).to be_truthy
    expect(calculation.errors).to be_empty
    # expect 13 rows in result (12 month + first zero line)
    expect(calculation.result.size).to eq 13
  end

  it "with invalid params" do
    params[:rate] = 100_500 # this rate is very high
    calculation.perform
    expect(calculation.result).to be_empty
    expect(calculation.errors).to be_truthy
  end

  it "calculation results is correct" do
    calculation.perform
    total_interest = calculation.result.sum { |h| h[:interest].to_f }.round(2)
    expect(total_interest).to eq default_expected_interest
  end

  it "rate change final % on deposit" do
    calculation.perform
    high_rate_interest = total_interest(calculation)
    expect(high_rate_interest).to eq default_expected_interest

    params[:rate] = 2
    low_rate_interest = total_interest(
      Calculation.new(stringify_params).perform
    )
    expect(low_rate_interest).to eq 20.14
  end

  it "capitalization change final % on deposit" do
    calculation.perform
    monthly_capital_interest = total_interest(calculation)
    expect(monthly_capital_interest).to eq default_expected_interest

    params[:capital] = "quarterly"
    quarterly_capital_interest = total_interest(
      Calculation.new(stringify_params).perform
    )
    expect(quarterly_capital_interest).to eq 157.1
  end
end

def stringify_params
  JSON.parse(params.to_json)
end

def total_interest(calculation)
  calculation.result.sum { |h| h[:interest].to_f }.round(2)
end
