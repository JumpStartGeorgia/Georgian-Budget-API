require 'rails_helper'
require Rails.root.join('spec', 'validators', 'start_end_date_validator_spec')

RSpec.describe PriorityConnection, type: :model do
  include_examples 'StartEndDateValidator'

  let(:new_priority_connection) { create(:priority_connection) }

  it 'is valid with valid attributes' do
    expect(new_priority_connection.valid?).to eq(true)
  end

  it 'is unique' do
    connection = create(:priority_connection)

    identical_connection = build(:priority_connection,
      time_period_obj: connection.time_period_obj,
      direct: connection.direct,
      priority: connection.priority,
      priority_connectable: connection.priority_connectable
    )

    expect(identical_connection.valid?).to eq(false)
  end

  describe '.direct' do
    it 'returns only priority connections marked direct' do
      create_list(:priority_connection, 2, direct: true)
      create(:priority_connection, direct: false)

      expect(PriorityConnection.direct.length).to eq(2)
    end
  end

  describe '.indirect' do
    it 'returns only priority connections marked indirect' do
      create_list(:priority_connection, 2, direct: true)
      create(:priority_connection, direct: false)

      expect(PriorityConnection.indirect.length).to eq(1)
    end
  end

  describe '#priority_connectable' do
    it 'is required' do
      new_priority_connection.priority_connectable = nil
      expect(new_priority_connection).to have(1).error_on(:priority_connectable)
    end
  end

  describe '#priority' do
    it 'is required' do
      new_priority_connection.priority = nil
      expect(new_priority_connection).to have(1).error_on(:priority)
    end
  end

  describe '#time_period_obj=' do
    it "sets start date to time period's start date" do
      new_priority_connection.time_period_obj = Quarter.for_date(Date.new(2011, 2, 2))

      expect(new_priority_connection.start_date).to eq(Date.new(2011, 1, 1))
    end

    it "sets end date to time period's end date" do
      new_priority_connection.time_period_obj = Quarter.for_date(Date.new(2011, 2, 2))

      expect(new_priority_connection.end_date).to eq(Date.new(2011, 3, 31))
    end
  end

  describe '#direct' do
    it 'is required' do
      new_priority_connection.direct = nil
      expect(new_priority_connection).to have(1).error_on(:direct)
    end
  end
end