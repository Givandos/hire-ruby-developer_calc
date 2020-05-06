# frozen_string_literal: true

require "./main.rb"
require "rack/test"
require "./spec/spec_helper"

describe "Main App", type: :request do
  include Rack::Test::Methods

  def app
    Main.new
  end

  let(:params) do
    {
      amount: 100,
      rate: "15",
      currency: "uah",
      start_date: Time.now + 1,
      duration_period: "month",
      deposit_duration: 5,
      capital: "monthly"
    }
  end

  it "GET request returns html form" do
    get "/"
    expect(last_response.body).not_to be_empty
    expect_ok
  end

  context "POST request" do
    it "without params" do
      post "/"
      expect_exception
    end

    it "with correct params" do
      post "/", params
      expect(last_response.content_type).to match(%r{text/html})
      expect_ok
    end

    it "with invalid params" do
      post "/", { currency: "bitcoin" }
      expect_unprocessable_entity
    end

    it "with json-request" do
      json_headers
      post "/", params.to_json
      expect(last_response.content_type).to match(%r{application/json})
      expect_ok
    end
  end
end

def expect_ok
  expect(last_response.status).to eq 200
end

def expect_unprocessable_entity
  expect(last_response.status).to eq 422
end

def expect_exception(status = 500)
  expect(last_response.status).to eq status
end

def json_headers
  header "Accept", "application/json"
  header "Content-Type", "application/json"
end
