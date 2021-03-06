require 'rails_helper'

RSpec.describe PriorityFinancer::Main do
  let(:priority) { FactoryGirl.create(:priority) }

  let(:do_update_finances!) do
    PriorityFinancer::Main.new(priority).update_finances
  end

  describe '#update_finances' do
    context 'when priority has no direct connections' do
      it 'adds no spent finances to priority' do
        do_update_finances!

        expect(priority.spent_finances.length).to eq(0)
      end

      it 'adds no planned finances to priority' do
        do_update_finances!

        expect(priority.planned_finances.length).to eq(0)
      end
    end

    context 'when priority has items with spent finances' do
      let(:jan_2012) { Month.for_date(Date.new(2012, 1, 1)) }
      let(:year_2012) { Year.new(2012) }

      let(:program) { create(:program) }
      let(:agency) { create(:spending_agency) }

      before do
        # program spent
        create(:spent_finance, time_period_obj: Year.new(2011),
          finance_spendable: program)

        create(:spent_finance, time_period_obj: jan_2012,
          finance_spendable: program)

        create(:spent_finance, time_period_obj: year_2012,
          finance_spendable: program)

        create(:spent_finance, time_period_obj: Year.new(2013),
          finance_spendable: program)

        # agency spent
        create(:spent_finance, time_period_obj: jan_2012,
          finance_spendable: agency)

        # connect them to priority
        create(:priority_connection,
          priority: priority,
          priority_connectable: program,
          time_period_obj: year_2012,
          direct: true)

        create(:priority_connection,
          priority: priority,
          priority_connectable: program,
          time_period_obj: Year.new(2013),
          direct: false)

        create(:priority_connection,
          priority: priority,
          priority_connectable: agency,
          time_period_obj: year_2012,
          direct: true)
      end

      it 'saves sums of directly connected spent finances' do
        do_update_finances!

        expect(priority.all_spent_finances.length).to eq(2)
        expect(priority.all_spent_finances.map(&:time_period_obj))
        .to contain_exactly(jan_2012, year_2012)

        expect(priority.all_spent_finances.with_time_period(jan_2012)[0].amount)
        .to eq(
          program.spent_finances.with_time_period(jan_2012)[0].amount +
          agency.spent_finances.with_time_period(jan_2012)[0].amount
        )
      end
    end

    context 'when priority has items with planned finances' do
      let(:jan_2012) { Month.for_date(Date.new(2012, 1, 1)) }
      let(:year_2012) { Year.new(2012) }

      let(:program) { create(:program) }
      let(:agency) { create(:spending_agency) }

      before do
        create(:planned_finance,
          time_period_obj: Year.new(2011),
          finance_plannable: program)

        create(:planned_finance,
          time_period_obj: jan_2012,
          finance_plannable: program,
          announce_date: Date.new(2011, 1, 1))

        create(:planned_finance,
          time_period_obj: jan_2012,
          finance_plannable: program,
          announce_date: Date.new(2012, 1, 1))

        create(:planned_finance,
          time_period_obj: year_2012,
          finance_plannable: program,
          announce_date: Date.new(2011, 1, 1))

        create(:planned_finance,
          time_period_obj: Year.new(2013),
          finance_plannable: program)

        # agency spent
        create(:planned_finance,
          time_period_obj: jan_2012,
          finance_plannable: agency,
          announce_date: Date.new(2011, 1, 1))

        # connect them to priority
        create(:priority_connection,
          priority: priority,
          priority_connectable: program,
          time_period_obj: year_2012,
          direct: true)

        create(:priority_connection,
          priority: priority,
          priority_connectable: program,
          time_period_obj: Year.new(2013),
          direct: false)

        create(:priority_connection,
          priority: priority,
          priority_connectable: agency,
          time_period_obj: year_2012,
          direct: true)
      end

      it 'saves sums of directly connected planned finances' do
        do_update_finances!

        expect(priority.all_planned_finances.length).to eq(3)

        expect(priority.all_planned_finances.map(&:time_period_obj))
        .to contain_exactly(jan_2012, jan_2012, year_2012)

        expect(priority.all_planned_finances.map(&:announce_date))
        .to contain_exactly(Date.new(2011, 1, 1), Date.new(2011, 1, 1), Date.new(2012, 1, 1))

        jan_2012_announced_2011 = priority
        .all_planned_finances
        .with_time_period(jan_2012)
        .where(announce_date: Date.new(2011, 1, 1))
        .first

        expect(jan_2012_announced_2011.amount).to eq(
          program
          .planned_finances
          .with_time_period(jan_2012)
          .where(announce_date: Date.new(2011, 1, 1))
          .first
          .amount +
          agency
          .planned_finances
          .with_time_period(jan_2012)
          .where(announce_date: Date.new(2011, 1, 1))
          .first
          .amount
        )

        jan_2012_announced_2012 = priority
        .all_planned_finances
        .with_time_period(jan_2012)
        .where(announce_date: Date.new(2012, 1, 1))
        .first

        expect(jan_2012_announced_2012.amount).to eq(
          program
          .planned_finances
          .with_time_period(jan_2012)
          .where(announce_date: Date.new(2012, 1, 1))
          .first
          .amount +
          agency
          .planned_finances
          .with_time_period(jan_2012)
          .where(announce_date: Date.new(2011, 1, 1))
          .first
          .amount
        )
      end
    end
  end
end
