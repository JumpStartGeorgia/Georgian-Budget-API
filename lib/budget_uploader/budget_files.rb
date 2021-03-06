require 'rubyXL'
require_relative 'budget_item_translations'
require_relative 'priorities_list'
require_relative 'duplicate_pairs_list'
require_relative 'priority_associations/list'

class BudgetFiles
  attr_reader :monthly_sheets,
              :yearly_sheets,
              :budget_item_translations,
              :priorities_list,
              :priority_associations_list,
              :start_time,
              :time_prettifier,
              :duplicate_pairs_list,
              :delete_all_budget_data

  def self.monthly_spreadsheet_dir
    budget_files_from_government.join('monthly_spreadsheets')
  end

  def self.yearly_spreadsheet_dir
    budget_files_from_government.join('yearly_spreadsheets')
  end

  def self.english_translations_file
    budget_files_not_from_government.join('budget_item_translations.csv').to_s
  end

  def self.priorities_list
    budget_files_not_from_government.join('priorities_list.csv').to_s
  end

  def self.priority_associations_list
    budget_files_not_from_government.join('priority_associations.csv').to_s
  end

  def self.duplicate_pairs_file
    budget_files_not_from_government.join('duplicate_pairs.csv').to_s
  end

  def self.budget_files_from_government
    budget_files_repo_dir.join('files_from_government')
  end

  def self.budget_files_not_from_government
    budget_files_repo_dir.join('files_not_from_government')
  end

  def self.budget_files_repo_dir
    Rails.root.join('budget_files', 'repo')
  end

  def initialize(args = {})
    options = default_options.merge(args)

    @start_time = Time.now
    @num_monthly_sheets_processed = 0
    @end_messages = []
    @time_prettifier = TimePrettifier.new
    @budget_item_translations = get_budget_item_translations(options)
    @monthly_sheets = get_monthly_sheets(options)
    @yearly_sheets = get_yearly_sheets(options)
    @priorities_list = get_priorities_list(options)
    @priority_associations_list = get_priority_associations_list(options)
    @duplicate_pairs_list = get_duplicate_pairs_list(options)
    @delete_all_budget_data = options[:delete_all_budget_data]
  end

  def default_options
    {
      delete_all_budget_data: false
    }
  end

  def upload
    print_start_messages

    Deleter.delete_all_budget_data if delete_all_budget_data

    upload_monthly_sheets if monthly_sheets.present?
    upload_yearly_sheets if yearly_sheets.present?
    save_priorities_list if priorities_list.present?
    save_priority_associations_list if priority_associations_list.present?
    save_budget_item_translations if budget_item_translations.present?
    process_duplicate_pairs if duplicate_pairs_list.present?
    save_other_time_period_spent_finances
    save_priority_finances
    destroy_non_duplicate_pairs
    export_csvs unless ENV['RAILS_ENV'] == 'test'

    print_end_messages
  end

  private

  attr_accessor :num_monthly_sheets_processed,
                :end_messages

  def get_priority_associations_list(args)
    return nil unless args[:priority_associations_list].present?
    PriorityAssociations::List.new_from_file(
      args[:priority_associations_list],
      priorities_list: priorities_list
    )
  end

  def get_priorities_list(args)
    return nil unless args[:priorities_list].present?
    PrioritiesList.new_from_file(args[:priorities_list])
  end

  def get_monthly_sheets(args)
    if args[:monthly_paths]
      monthly_sheet_paths = args[:monthly_paths]
    elsif args[:monthly_folder]
      monthly_sheet_paths = MonthlyBudgetSheet::File.file_paths(args[:monthly_folder])
    end

    return nil unless monthly_sheet_paths.present?

    monthly_sheet_paths.map do |monthly_sheet_path|
      MonthlyBudgetSheet::File.new_from_file(monthly_sheet_path)
    end.sort do |sheet1, sheet2|
      sheet1.publish_date <=> sheet2.publish_date
    end
  end

  def get_yearly_sheets(args)
    if args[:yearly_paths]
      yearly_sheet_paths = args[:yearly_paths]
    elsif args[:yearly_folder]
      yearly_sheet_paths = YearlyBudgetSheet::File.file_paths(args[:yearly_folder])
    end

    return nil unless yearly_sheet_paths.present?

    yearly_sheet_paths.map do |yearly_sheet_path|
      YearlyBudgetSheet::File.new_from_file(yearly_sheet_path)
    end.sort do |sheet1, sheet2|
      sheet1.publish_date <=> sheet2.publish_date
    end
  end

  def get_budget_item_translations(args)
    return nil unless args[:budget_item_translations]

    BudgetItemTranslations.new(args[:budget_item_translations])
  end

  def get_duplicate_pairs_list(args)
    duplicate_pairs_file_path = args[:duplicate_pairs_file]
    return nil unless duplicate_pairs_file_path.present?

    DuplicatePairsList.new(duplicate_pairs_file_path)
  end

  def upload_monthly_sheets
    puts "\nSaving monthly budget spreadsheet data"
    time_prettifier.run do
      monthly_sheets.each do |monthly_sheet|
        ActiveRecord::Base.transaction do
          monthly_sheet.save_data
        end

        self.num_monthly_sheets_processed = num_monthly_sheets_processed + 1
      end
    end
    finished_message = "Finished saving monthly budget spreadsheet data in #{time_prettifier.elapsed_prettified}"

    puts finished_message
    end_messages << finished_message
    end_messages << "Number of monthly budget sheets processed: #{num_monthly_sheets_processed}"
    end_messages << "Average time per monthly budget sheet: #{time_prettifier.prettify(time_prettifier.elapsed/num_monthly_sheets_processed)}"
  end

  def upload_yearly_sheets
    puts "\nSaving yearly budget spreadsheet data"

    num_yearly_sheets_processed = 0

    time_prettifier.run do
      yearly_sheets.each do |yearly_sheet|
        ActiveRecord::Base.transaction do
          yearly_sheet.save_data
        end

        num_yearly_sheets_processed = num_yearly_sheets_processed + 1
      end
    end

    finished_message = "Finished saving yearly budget spreadsheet data in #{time_prettifier.elapsed_prettified}"

    puts finished_message
    end_messages << finished_message
    end_messages << "Number of yearly budget sheets processed: #{num_yearly_sheets_processed}"
    end_messages << "Average time per yearly budget sheet: #{time_prettifier.prettify(time_prettifier.elapsed/num_yearly_sheets_processed)}"
  end

  def save_priorities_list
    puts "\nSaving priorities list"
    time_prettifier.run do
      priorities_list.save
    end

    finished_message = "Finished saving priorities list in #{time_prettifier.elapsed_prettified}"

    puts finished_message
    end_messages << finished_message
  end

  def save_priority_associations_list
    puts "\nSaving priority associations list"
    time_prettifier.run do
      priority_associations_list.save
    end

    finished_message = "Finished priority associations list in #{time_prettifier.elapsed_prettified}"

    puts finished_message
    end_messages << finished_message
  end

  def save_budget_item_translations
    puts "\nSaving budget item translations list"
    time_prettifier.run do
      budget_item_translations.save
    end

    finished_message = "Finished saving budget item translations in #{time_prettifier.elapsed_prettified}"

    puts finished_message
    end_messages << finished_message
  end

  def save_priority_finances
    puts "\nSaving priority finances"
    time_prettifier.run do
      Priority.all.each do |priority|
        PriorityFinancer::Main.new(priority).update_finances
      end
    end
    finished_message = "Finished saving priority finances in #{time_prettifier.elapsed_prettified}"
    puts finished_message

    end_messages << finished_message
  end

  def save_other_time_period_spent_finances
    puts "\nSaving quarterly and yearly spent finances"
    time_prettifier.run do
      SpentFinanceAggregator.new.create_from_monthly(Quarter)
      SpentFinanceAggregator.new.create_from_monthly(Year)
    end

    finished_message = "Finished saving quarterly and yearly spent finances in #{time_prettifier.elapsed_prettified}"
    puts finished_message
    end_messages << finished_message
  end

  def process_duplicate_pairs
    puts "\nProcessing duplicate pairs"
    time_prettifier.run do
      @duplicate_pairs_list.process
    end

    finished_message = "Finished processing duplicate pairs in #{time_prettifier.elapsed_prettified}"
    puts finished_message
    end_messages << finished_message
  end

  def destroy_non_duplicate_pairs
    WrongDuplicateDestroyer.new.destroy_non_duplicate_pairs(PossibleDuplicatePair.all)
  end

  def export_csvs
    Csv::SuspiciousItems.new(
      directory_path: Rails.root.join('tmp', 'suspicious_items')
    ).export
  end

  def print_start_messages
    puts "\nBEGIN: Budget Uploader"
  end

  def print_end_messages
    puts "\nEND: Budget Uploader"
    puts "-----Report-----"
    end_messages << "Total time elapsed: #{time_prettifier.prettify(total_elapsed_time)}"

    end_messages.each { |end_message| puts end_message }
  end

  def elapsed_since_start
    Time.at(total_elapsed_time).utc.strftime("%H:%M:%S").to_s
  end

  def total_elapsed_time
    Time.now - start_time
  end
end
