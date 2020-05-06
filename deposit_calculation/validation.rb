# frozen_string_literal: true

# params validation
class Validation
  REQUIRED_PARAMS = %i[amount currency rate start_date
                       duration_period deposit_duration capital].freeze
  MIN_AMOUNT = 1
  MIN_RATE = 1
  MAX_RATE_IN_UAH = 30
  MAX_RATE_IN_USD = 7
  MAX_RATE_IN_EUR = 6
  MIN_DURATION = 1
  MAX_DURATION_IN_MONTH = 120
  MAX_DURATION_IN_YEAR = 10
  CURRENCIES = %i[uah usd eur].freeze
  PERIODS = %i[month year].freeze
  CAPITAL_OPTIONS = %i[nothing monthly quarterly yearly].freeze

  attr_reader :params, :errors

  def initialize(params)
    raise ArgumentError, "params is required" if params.nil? || params.empty?

    @params = params.transform_keys(&:to_sym)
    @errors = []
  end

  def perform
    REQUIRED_PARAMS.each do |name|
      if params[name].nil? || params[name].to_s.strip.empty?
        errors << { name => "#{name} can't be empty" }
      else
        send("validate_#{name}")
      end
    end

    self
  end

  def valid?
    @errors.empty?
  end

  private

  def validate_amount
    return if params[:amount].to_f >= MIN_AMOUNT

    errors << { amount: "minimal amount of deposit is #{MIN_AMOUNT}" }
  end

  def validate_currency
    return if currency_valid?

    errors << { currency: "#{params[:currency]} is not valid currency" }
  end

  def validate_rate
    return unless currency_valid?

    max_possible_rate = from_constant("max_rate_in_#{params[:currency]}")

    return if params[:rate].to_f.between?(MIN_RATE, max_possible_rate)

    errors << { rate: "annual #{params[:currency].upcase} rate has to be " \
                      "between #{MIN_RATE}% and #{max_possible_rate}%" }
  end

  def validate_start_date
    return if Time.parse(params[:start_date]) > Time.now

    errors << { start_date: "you can't open deposit in past" }
  end

  def validate_duration_period
    return if duration_period_valid?

    errors << { duration_period: "#{params[:duration_period]} is not valid " \
                                 "type of duration period" }
  end

  def validate_deposit_duration
    return unless duration_period_valid?

    max_possible_duration = from_constant(
      "max_duration_in_#{params[:duration_period]}"
    )

    duration = params[:deposit_duration].to_i

    return if duration.between?(MIN_DURATION, max_possible_duration)

    errors << { deposit_duration: "deposit duration has to be between " \
                                  "#{MIN_DURATION} and " \
                                  "#{max_possible_duration}" }
  end

  def validate_capital
    return if capital_valid?

    errors << { capital: "#{params[:capital]} is not valid capitalization " \
                         "type" }
  end

  def currency_valid?
    CURRENCIES.include?(params[:currency].to_sym)
  end

  def duration_period_valid?
    PERIODS.include?(params[:duration_period].to_sym)
  end

  def capital_valid?
    CAPITAL_OPTIONS.include?(params[:capital].to_sym)
  end

  def from_constant(const_name)
    self.class.const_get(const_name.upcase)
  end
end
