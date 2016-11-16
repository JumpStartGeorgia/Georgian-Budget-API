require 'rails_helper'
require Rails.root.join('lib', 'budget_uploader', 'budget_files').to_s

RSpec.describe 'BudgetFiles' do
  describe '#upload' do
    context 'with yearly spreadsheets' do
      before :example do
        I18n.locale = 'ka'
      end

      before :context do
        Program.create
        .add_name(FactoryGirl.attributes_for(:name,
          text_ka: 'მეცნიერებისა და სამეცნიერო კვლევების ხელშეწყობა'))
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 04 02',
          start_date: Date.new(2015, 1, 1)))
        .reload
        .save_perma_id
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 05',
          start_date: Date.new(2016, 1, 1)))
        .reload
        .save_perma_id

        Program.create
        .add_name(FactoryGirl.attributes_for(:name,
          text_ka: 'სახელმწიფო სასწავლო, სამაგისტრო გრანტები და ახალგაზრდების წახალისება'))
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 04 03',
          start_date: Date.new(2015, 1, 1)))
        .reload
        .save_perma_id
        .add_code(FactoryGirl.attributes_for(:code,
          number: '32 04 02',
          start_date: Date.new(2016, 1, 1)))
        .reload
        .save_perma_id

        yearly_files_dir = BudgetFiles.yearly_spreadsheet_dir

        BudgetFiles.new(
          yearly_paths: [
            yearly_files_dir.join('yearly_spreadsheet-2015-original-formatted.xlsx').to_s,
            yearly_files_dir.join('yearly_spreadsheet-2016-original-formatted.xlsx').to_s
          ]
        ).upload
      end

      after :context do
        [Program, SpendingAgency, Priority, Total].each(&:destroy_all)
      end

      describe 'total:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '00',
            name: 'მთლიანი სახელმწიფო ბიუჯეტი'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(8104217.6)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(9080000.0)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.all_planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(9575000.0)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(9009812.2)
        end

        it 'saved the 2015 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(9620000.0)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(10145000.0)
        end
      end

      describe '24 00 agency:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '24 00',
            name: 'საქართველოს ეკონომიკისა და მდგრადი განვითარების სამინისტრო'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(123541.4)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(131091.0)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.all_planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(120000.0)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(88395.6)
        end

        it 'saved the 2015 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(85368.1)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(95100.0)
        end
      end

      describe '32 04 02 მეცნიერებისა და სამეცნიერო კვლევების ხელშეწყობა:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '32 04 02',
            name: 'მეცნიერებისა და სამეცნიერო კვლევების ხელშეწყობა'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(27115.1)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(49707.0)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.all_planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(60500.0)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(32410.1)
        end

        it 'saved the 2015 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(60417.4)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(66747.0)
        end
      end

      describe '32 04 02 სახელმწიფო სასწავლო, სამაგისტრო:' do
        let(:budget_item) do
          BudgetItem.find(
            code: '32 04 02',
            name: 'სახელმწიფო სასწავლო, სამაგისტრო გრანტები და ახალგაზრდების წახალისება'
          )
        end

        it 'saved the 2013 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2013))
          .first

          expect(finance.amount.to_f).to eq(59208.7)
        end

        it 'saved the 2014 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2014))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(76440.0)
        end

        it 'saved the 2015 plan announced in 2015' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2015))
          .where(announce_date: Date.new(2015, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(82663.0)
        end

        it 'saved the 2014 spent amount' do
          finance = budget_item.spent_finances
          .with_time_period(Year.new(2014))
          .first

          expect(finance.amount.to_f).to eq(74918.7)
        end

        it 'saved the 2016 plan announced in 2016' do
          finance = budget_item.planned_finances
          .with_time_period(Year.new(2016))
          .where(announce_date: Date.new(2016, 1, 1))
          .first

          expect(finance.amount.to_f).to eq(89611.0)
        end
      end
    end
  end
end