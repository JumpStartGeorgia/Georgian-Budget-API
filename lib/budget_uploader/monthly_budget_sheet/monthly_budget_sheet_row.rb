class MonthlyBudgetSheetRow
  def initialize(row_data)
    @row_data = row_data
  end

  # returns true if this is the header row of an item
  def is_header?
    return false if cells.empty?

    code_is_left_aligned && third_cell_is_empty
  end

  def code
    cells[0].value.strip
  end

  def name
    cells[1].value.strip
  end

  def planned_finance
    cells[2].value.to_i
  end

  def spent_finance
    cells[6].value.to_i
  end

  private

  def code_is_left_aligned
    cells[0].horizontal_alignment == 'left'
  end

  def third_cell_is_empty
    cells[2].nil? || cells[2].value.nil? || cells[2].value.strip == ''
  end

  def cells
    row_data.cells
  end

  attr_reader :row_data
end
