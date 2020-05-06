# frozen_string_literal: true

require "./deposit_calculation/validation"

# calculation of deposit
class Calculation
  attr_reader :result, :params, :errors

  def initialize(params)
    raise ArgumentError, "params is required" if params.nil? || params.empty?

    @params = params.transform_keys!(&:to_sym)

    validation = Validation.new(params).perform

    @errors = validation.errors
    @result = []
    @amount = params[:amount].to_f
    @deposited_interest = 0
  end

  def perform
    calculate if @errors.empty?

    self
  end

  private

  attr_reader :amount, :deposited_interest

  def calculate
    date = Date.parse(params[:start_date])
    amount_of_days = nil
    months_amount.times do |index|
      @result << month_statistics(index, date, amount_of_days)
      amount_of_days = amount_days_in_month(date.month, date.year)
      date += amount_of_days
    end
  end

  def month_statistics(month_index, next_date, count_of_days)
    monthly_interest = (daily_interest * count_of_days.to_i).round(2)
    capitalization_of_amount(month_index)
    @deposited_interest += monthly_interest

    { index: month_index,
      date: next_date,
      days_counter: count_of_days,
      amount: amount.round(2),
      replenish: nil,
      withdraw: nil,
      interest: monthly_interest }
  end

  def months_amount
    coefficient =
      if params[:duration_period] == "year"
        12
      else
        1
      end

    params[:deposit_duration].to_i * coefficient + 1
  end

  def daily_interest
    daily_rate = params[:rate].to_f / 365

    amount.to_i * daily_rate / 100
  end

  def capitalization_of_amount(month_index)
    return if month_index.zero? ||
              !capitalization_needed?(month_index)

    interest_to_amount
  end

  def interest_to_amount
    @amount += deposited_interest
    @deposited_interest = 0
  end

  def capitalization_needed?(month_index)
    capitalization_monthly? ||
      capitalization_quarterly?(month_index) ||
      capitalization_yearly?(month_index)
  end

  def capitalization_monthly?
    params[:capital] == "monthly"
  end

  def capitalization_quarterly?(month_index)
    params[:capital] == "quarterly" && (month_index % 3).zero?
  end

  def capitalization_yearly?(month_index)
    params[:capital] == "yearly" && (month_index % 12).zero?
  end
end
