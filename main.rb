# frozen_string_literal: true

require "sinatra"
require "pry"
require "./helpers/helpers"
require "./deposit_calculation/calculation"

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
    halt 422, calculation.errors.to_json unless calculation.errors.empty?

    halt calculation.result.to_json
  else
    @params = calculation.params
    @result = calculation.result
    @errors = calculation.errors
    return erb :calculation
  end
end
