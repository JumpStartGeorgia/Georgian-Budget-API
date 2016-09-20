class HighchartsTimeSeries
  def initialize(budget_item, item_data)
    @budget_item = budget_item
    @unformatted_data = item_data
  end

  def config
    {
      name: budget_item.name,
      data: data
    }
  end

  attr_reader :budget_item, :unformatted_data

  private

  def data
    {
      time_periods: time_period_months,
      amounts: amounts
    }
  end

  def amounts
    unformatted_data.map { |point| point.amount.to_f }
  end

  def time_period_months
    time_periods.map(&:month)
  end

  def time_periods
    unformatted_data.map do |data_point|
      TimePeriod.new(data_point.start_date, data_point.end_date)
    end
  end
end