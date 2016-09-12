require 'rails_helper'

RSpec.describe SpentFinance do
  let(:finance_spendable1) { FactoryGirl.create(:program) }

  let(:spent_finance1) do
    FactoryGirl.create(
      :spent_finance,
      start_date: Date.new(2014, 12, 1),
      end_date: Date.new(2014, 12, 31)
    )
  end

  let(:spent_finance1b) do
    FactoryGirl.create(
      :spent_finance,
      start_date: spent_finance1.end_date + 1,
      end_date: spent_finance1.end_date + 30
    )
  end

  let(:spent_finance1c) do
    FactoryGirl.create(
      :spent_finance,
      start_date: spent_finance1b.end_date + 1,
      end_date: spent_finance1b.end_date + 30
    )
  end

  let(:spent_finance1d) do
    FactoryGirl.create(
      :spent_finance,
      start_date: spent_finance1c.end_date + 1,
      end_date: spent_finance1c.end_date + 30
    )
  end

  describe '.year_cumulative_up_to' do
    it 'gets amount spent between beginning of the year and provided date' do
      # in 2014
      spent_finance1.save!

      # in 2015
      spent_finance1b.save!
      spent_finance1c.save!
      spent_finance1d.save!

      amount_spent = SpentFinance.all.year_cumulative_up_to(
        spent_finance1c.end_date
      )



      expect(amount_spent).to eq(spent_finance1b.amount + spent_finance1c.amount)
    end
  end

  describe '.before' do
    it 'gets the spent finances before a certain date' do
      spent_finance1.save!
      spent_finance1b.save!

      expect(SpentFinance.all.before(spent_finance1.end_date))
      .to match_array([spent_finance1])
    end
  end

  describe '.after' do
    it 'gets the spent finances after a certain date' do
      spent_finance1.save!
      spent_finance1b.save!

      expect(SpentFinance.all.after(spent_finance1b.start_date))
      .to match_array([spent_finance1b])
    end
  end

  describe '.total' do
    it 'gets the sum of the spent finance amounts' do
      spent_finance1.save!
      spent_finance1b.save!

      expect(SpentFinance.all.total).to eq(
        spent_finance1.amount + spent_finance1b.amount
      )
    end
  end
end
