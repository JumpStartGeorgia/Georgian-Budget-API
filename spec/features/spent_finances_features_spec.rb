require 'rails_helper'

RSpec.describe 'ActualFinances' do
  it 'are displayed on the show page of a program' do
    program1 = FactoryGirl.create(:program_with_name)

    spent_finance1 = FactoryGirl.create(
      :spent_finance,
      finance_spendable: program1
    )

    spent_finance2 = FactoryGirl.create(
      :spent_finance,
      start_date: spent_finance1.start_date,
      end_date: spent_finance1.start_date + 1,
      finance_spendable: program1
    )

    visit program_path(program1)

    expect(page).to have_content("#{spent_finance1.start_date} - #{spent_finance1.end_date}: #{spent_finance1.amount}")
    expect(page).to have_content("#{spent_finance2.start_date} - #{spent_finance2.end_date}: #{spent_finance2.amount}")
  end
end
