# frozen_string_literal: true

def json?
  request.accept.any? { |accept| accept.entry == "application/json" }
end

def html?
  request.accept.any? { |accept| accept.entry == "text/html" }
end

def amount_days_in_month(month, year = Time.now.year)
  days_in_month = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  return 29 if month == 2 && Date.gregorian_leap?(year)

  days_in_month[month]
end
