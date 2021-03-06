module MonthlyBudgetSheet
  class ItemSaver
    def initialize(monthly_sheet_item, args = {})
      @monthly_sheet_item = monthly_sheet_item
      @publish_date = args[:publish_date]
    end

    def save_data_from_monthly_sheet_item
      BudgetDataSaver.new(self).save_data
    end

    def code_data
      {
        start_date: publish_date,
        number: code_number
      }
    end

    def name_data
      {
        text_ka: name_text,
        text_en: nil,
        start_date: publish_date
      }
    end

    def spent_finance_data
      {
        time_period_obj: month,
        amount: spent_finance_cumulative,
        official: true
      }
    end

    def planned_finance_data
      {
        time_period_obj: quarter,
        announce_date: publish_date,
        amount: planned_finance_cumulative,
        official: true
      }
    end

    def name_text
      Name.clean_text(monthly_sheet_item.name_text)
    end

    def code_number
      monthly_sheet_item.primary_code
    end

    attr_reader :monthly_sheet_item,
                :publish_date

    private

    def spent_finance_cumulative
      monthly_sheet_item.spent_finance_cumulative
    end

    def month
      Month.for_date(publish_date)
    end

    def planned_finance_cumulative
      monthly_sheet_item.planned_finance_cumulative
    end

    def quarter
      Quarter.for_date(publish_date)
    end
  end
end
