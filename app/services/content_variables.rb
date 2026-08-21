class ContentVariables
  CURRENT_YEAR_PATTERN = /\{YYYY\}/i
  CURRENT_MONTH_PREPOSITIONAL_PATTERN = /\{MONTH_PRED\}/i
  MONTHS_PREPOSITIONAL = %w[
    январе феврале марте апреле мае июне
    июле августе сентябре октябре ноябре декабре
  ].freeze

  def self.render(value, time: Time.current)
    return value if value.blank?

    value.to_s
      .gsub(CURRENT_YEAR_PATTERN, time.year.to_s)
      .gsub(CURRENT_MONTH_PREPOSITIONAL_PATTERN, month_prepositional(time: time))
  end

  def self.month_prepositional(time: Time.current) = MONTHS_PREPOSITIONAL.fetch(time.month - 1)
end
