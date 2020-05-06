# frozen_string_literal: true

require "sinatra"
require "pry"
require "./helpers/helpers"
require "./deposit_calculation/calculation"

# main application class
class Main < Sinatra::Base
  get "/" do
    erb :calculation
  end

  post "/" do
    calculation = Calculation.new(
      if json?
        JSON.parse(request.body.read)
      else
        request.params
      end
    ).perform

    if json?
      content_type "application/json"
      halt 422, calculation.errors.to_json unless calculation.errors.empty?

      halt calculation.result.to_json
    else
      @params = calculation.params
      @result = calculation.result
      @errors = calculation.errors
      status 422 unless @errors.empty?
      erb :calculation
    end
  end
end
