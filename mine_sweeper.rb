class MinesSweeper
  SIZE = 9

  def initialize
    @board =[]
    @row = []
    SIZE.times { @row << Cell.new }
    SIZE.times { @board << @row }  # Now board is generically filled with Cells
  end



# populate board (9x9 or 16x16) generically
# pick random cells to flip the bomb? switch ON

# good to begin!



# reveal method and flag method

# flag method will add to flagged squares
# unflag method will remove a flag from a square
  def print_board

    @board.each do |row|
      print row.inspect
    end
  end

end

class Cell
  attr_accessor :flagged, :bomb, :neighboring_bombs, :revealed
  def initialize
    @flagged = false
    @bomb = false
    @neighboring_bombs = 0
    @revealed = false
  end
end


# SCRIPT

m = MinesSweeper
m.print_board