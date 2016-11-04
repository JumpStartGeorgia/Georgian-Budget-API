module MonthlyBudgetSheet
  class File
    def self.file_paths(folder)
      Dir.glob(Pathname.new(folder).join(self.file_name_glob))
    end

    def self.new_from_file(spreadsheet_path)
      new(spreadsheet_path: spreadsheet_path)
    end

    def initialize(args = {})
      @spreadsheet_path = args[:spreadsheet_path]
      @excel_data = args[:excel_data]
      @start_date = args[:start_date]

      @code_column = nil
      @name_column = nil
      @spent_finance_column = nil
      @planned_finance_column = nil

      @warnings = []
    end

    def save_data
      puts "Saving data in monthly budget sheet: #{spreadsheet_path}"

      current_item = nil

      I18n.locale = 'ka'

      data_rows.each_with_index do |row_data, index|
        row = create_row(row_data)

        set_columns(row) if !columns_set? && row.contains_column_names?

        next unless row.contains_data?

        if row.is_header?
          unless columns_set?
            raise "Could not find column headers for spreadsheet: #{spreadsheet_path}"
          end

          if current_item.present?
            # save the previous budget item
            ItemSaver.new(
              current_item,
              start_date: start_date,
              warnings: warnings
            ).save_data_from_monthly_sheet_item
          end

          # create a new budget item
          current_item = Item.new(header_row: row)
        end

        if current_item.present? && row.is_totals_row?
          current_item.totals_row = row
        end
      end

      output_warnings
    end

    def output_warnings
      return if warnings.empty?

      puts "\nWARNINGS for Monthly Budget Spreadsheet #{Month.for_date(start_date)}"
      warnings.each { |warning| puts "WARNING: #{warning}" }
    end

    def data_rows
      get_excel_data unless excel_data.present?
      excel_data[0]
    end

    def excel_data
      @excel_data ||= get_excel_data
    end

    def start_date
      @start_date ||= get_start_date
    end

    attr_reader :spreadsheet_path,
                :warnings

    attr_accessor :code_column,
                  :name_column,
                  :spent_finance_column,
                  :planned_finance_column

    private

    def get_excel_data
      require 'rubyXL'
      RubyXL::Parser.parse(spreadsheet_path)
    end

    def set_columns(row)
      @code_column = row.column_number_for_values(['ორგანიზაც. კოდი', 'ორგანიზაც კოდი'])
      @name_column = row.column_number_for_value('დ ა ს ა ხ ე ლ ე ბ ა')
      @spent_finance_column = row.column_number_for_value('გადახდა')
      @planned_finance_column = row.column_number_for_value('გეგმა')
    end

    def columns_set?
      @code_column.present? && @name_column.present? && @spent_finance_column.present? && @planned_finance_column.present?
    end

    def create_row(row_data)
      Row.new(
        row_data,
        {
          code_column: code_column,
          name_column: name_column,
          spent_finance_column: spent_finance_column,
          planned_finance_column: planned_finance_column
        }
      )
    end

    def get_start_date
      Date.new(date_regex_match[2].to_i, date_regex_match[1].to_i, 1)
    end

    def date_regex_match
      match = filename_date_regex.match(spreadsheet_path)
      raise 'Cannot parse date from filename. Format of file should be monthly_spreadsheet.mm.yyyy' if match.nil?

      match
    end

    def filename_date_regex
      /monthly_spreadsheet.*?(\w+)\.(\w+).xlsx/
    end

    def file_name_glob
      '**/monthly_spreadsheet*.xlsx'
    end
  end
end
