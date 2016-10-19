require 'rails_helper'

RSpec.describe MonthlyBudgetSheet::File do
  let(:total) { FactoryGirl.create(:total, code: '00') }

  it 'gets the right values for January, 2012' do
    total

    january_2012_sheet = Rails.root.join(
      'budget_files',
      'repo',
      'files',
      'monthly_spreadsheets',
      '2012',
      'monthly_spreadsheet-01.2012.xlsx'
    ).to_s

    MonthlyBudgetSheet::File.new(january_2012_sheet).save_data

    total.reload

    expect(total.spent_finances.last.amount).to eq(488834301.67)
  end

  it 'gets the right values for February, 2012' do
    previous_month = Month.for_date(Date.new(2012, 1, 1))

    FactoryGirl.create(
      :spent_finance,
      amount: 488834301.67,
      time_period: previous_month,
      finance_spendable: total
    )

    total

    february_2012_sheet = Rails.root.join(
      'budget_files',
      'repo',
      'files',
      'monthly_spreadsheets',
      '2012',
      'monthly_spreadsheet-02.2012.xlsx'
    ).to_s

    MonthlyBudgetSheet::File.new(february_2012_sheet).save_data
    total.reload

    expect(total.spent_finances.last.amount).to eq(530429467.19)
  end

  it 'gets the right values for April, 2014' do
    previous_month_date = Date.new(2014, 3, 1)
    FactoryGirl.create(
      :spent_finance,
      amount: 1847553147.46,
      time_period: Month.for_date(previous_month_date),
      finance_spendable: total
    )

    total.add_planned_finance(
      amount: 2269603100,
      time_period: Quarter.for_date(previous_month_date),
      announce_date: previous_month_date
    )

    april_2014_sheet = Rails.root.join(
      'budget_files',
      'repo',
      'files',
      'monthly_spreadsheets',
      '2014',
      'monthly_spreadsheet-04.2014.xlsx'
    ).to_s

    MonthlyBudgetSheet::File.new(april_2014_sheet).save_data

    total.reload

    expect(total.spent_finances.last.amount.to_f).to eq(656086999.08)
    expect(total.planned_finances.last.amount.to_f).to eq(4354890200 - 2269603100)
  end

  it 'gets the right values for August, 2014' do
    FactoryGirl.create(
      :spent_finance,
      amount: 4714720298.3,
      start_date: Date.new(2014, 7, 1),
      end_date: Date.new(2014, 7, 1).end_of_month,
      finance_spendable: total
    )

    august_2014_sheet = Rails.root.join(
      'budget_files',
      'repo',
      'files',
      'monthly_spreadsheets',
      '2014',
      'monthly_spreadsheet-08.2014.xlsx'
    ).to_s

    MonthlyBudgetSheet::File.new(august_2014_sheet).save_data

    total.reload

    expect(total.spent_finances.last.amount.to_f).to eq(637285988.22)
  end

  it 'gets the right values for September, 2014' do
    FactoryGirl.create(
      :spent_finance,
      amount: 5352006286.52,
      start_date: Date.new(2014, 8, 1),
      end_date: Date.new(2014, 8, 1).end_of_month,
      finance_spendable: total
    )

    total.add_planned_finance(
      amount: 4354890200,
      time_period: Quarter.for_date(Date.new(2014, 4, 1)),
      announce_date: Date.new(2014, 6, 1)
    )

    september_2014_sheet = Rails.root.join(
      'budget_files',
      'repo',
      'files',
      'monthly_spreadsheets',
      '2014',
      'monthly_spreadsheet-09.2014.xlsx'
    ).to_s

    MonthlyBudgetSheet::File.new(september_2014_sheet).save_data

    total.reload
    expect(total.spent_finances.last.amount.to_f).to eq(830795862.26)
    expect(total.planned_finances.last.amount.to_f).to eq(6747604300 - 4354890200)

    agency = SpendingAgency.find_by_code('01 00')
    expect(agency.name_ka).to eq('საქართველოს პარლამენტი და მასთან არსებული ორგანიზაციები')

    # Check that the name is corrected to have a short dash instead of a long dash
    program = Program.find_by_code('45 12')

    expect(program.name_ka).to eq('ა(ა)იპ - ახალქალაქისა და კუმურდოს ეპარქიის სასწავლო ცენტრისთვის გადასაცემი გრანტი')
  end
end