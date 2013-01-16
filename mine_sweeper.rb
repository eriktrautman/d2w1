#!/usr/bin/env ruby

# Erik and JT's Minesweeper

require 'yaml'

class PlayMineSweeper

  def initialize(filename = "")

    if filename.empty?
      m = MineSweeper.new
    else
      begin
        m = YAML.load(File.open(filename))
      rescue ArgumentError => e
        puts "Could not parse YAML: #{e.message}"
      end
    end
    m.play
  end

end

class MineSweeper

  VALID_MOVE_TYPES = ["f", "u", "r", "s", "q"]

  attr_reader :board

  def initialize(size = 9)
    @size = size
    @board =[]
    @size.times do |x|
      tmp_array = []
      @size.times {|y| tmp_array << Cell.new(x,y) }
      @board << tmp_array
    end
    @mines = @size ** 2 / 8

    populate_mines
    figure_out_cell_numbers
  end
def

   play

    puts "\nInitial board:\n"
    print_secret_board
    until victory?
      move = []

      # get input where move is array [x,y] and move_type is char "f" or "r"
      move_type, move = get_move

      if explosion?(move, move_type)
        puts  "\nKABOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOM!!!!!!!\n"
        print_board
        exit
      else
        execute_move(move, move_type)
        print_board
      end
    end

    puts "Winner."
  end

  private

  # asks user for move and type, returns that pair
  def get_move
    [get_user_move_type, get_user_coordinates]
  end

  def get_user_coordinates
    coords = [nil, nil]
    puts "Enter coordinates in the format: y,x and in the valid range of 0 to #{@size-1}."
    until valid_coords?(coords)
      coords = gets.chomp.split(",").map(&:to_i)
      puts "valid coords: #{coords.inspect} and are #{valid_coords?(coords)}"
    end
    coords
  end

  def valid_coords?(coords)
    valid_range = (0..@size-1)
    valid_range.include?(coords[0]) && valid_range.include?(coords[1])
  end

  def get_user_move_type
    move_type = ""
    puts "\nPick a valid move type, "
    puts "e.g. 'f' to place a flag or 'r' to reveal cell"
    puts "'s' will save the board and 'q' will quit the game."
    until VALID_MOVE_TYPES.include?(move_type)
      #print "#{$stdin}"
      move_type = gets.chomp.downcase
    end

    if move_type == "s"
      save_game_to_yaml
    elsif move_type == "q"
      exit
    end

    move_type
  end

  # pick random cells to flip the mine? switch ON
  def populate_mines
    mines_remaining = @mines
    until mines_remaining <= 0
      random_cell = @board.sample.sample
      unless random_cell.mine
        random_cell.mine = true
        mines_remaining -= 1
      end
    end
  end

  # go through all cells and calculate their number of neighboring mines
  def figure_out_cell_numbers
    @board.each do |row|
      row.each do |cell|
        cell.calculate_neighboring_mines(@board, @size)
      end
    end

  end

  def victory?
    @size.times do |x|
      @size.times do |y|
        cell = @board[x][y]
        if cell.mine && !cell.flagged
          return false
        elsif cell.revealed == false && !cell.mine
          return false
        end
      end
    end
    true
  end

  def explosion?(move_coords, move_type)
    move_type == "r" && @board[move_coords[0]][move_coords[1]].mine
  end

  # if reveal move type,
  def execute_move(move_coords, move_type)
    cell_object = @board[move_coords[0]][move_coords[1]]
    # if it's a flag move AND the cell hasn't been revealed
    # AND it's not already flagged, place flag
    if move_type == "f" && !cell_object.revealed && !cell_object.flagged
      cell_object.flagged = true

    elsif move_type == "u" && cell_object.flagged
      cell_object.flagged = false

    # if it's a reveal move AND hasn't yet been revealed
    elsif move_type == "r" && !cell_object.revealed
      # set that cell's reveal to true
      reveal(cell_object)
    end

  end

  # reveals the clicked cell and any around it until it hits nonzero cells
  # this is effectively breadth first search
  def reveal(cell_object)
    queue = [cell_object]

    # until we've emptied our queue, reveal the current cell, put any children
    # it has that are zero into the queue
    until queue.empty?

      # grab the first item in the queue
      active_cell = queue.shift

        # if that item is not a zero AND not a bomb
      if active_cell.neighboring_mines != 0 && active_cell.mine == false

        # reveal it and go to the next thing in the queue
        active_cell.revealed = true
        next

      # otherwise, if that item IS a zero (and not a bomb)
      elsif active_cell.neighboring_mines == 0 && active_cell.mine == false

        # reveal it
        active_cell.revealed = true

        # AND put all its neighbors into the queue if they haven't yet been revealed
        active_cell.get_neighbors(@board, @size).each do |cell| # would return an array of all valid neighbors

          # keep you if you haven't been revealed and are NOT in the queue already
          if !cell.revealed && !queue.include?(cell)
            queue << cell
          end
        end

      end
    end
  end

# unflag method will remove a flag from a square

  def print_secret_board

    @board.each do |row|
      row.each do |cell|
        if cell.mine
          print "* "
        elsif cell.neighboring_mines == 0
          print "- "
        else
          print "#{cell.neighboring_mines} "
        end
      end
      puts
    end
  end

  def print_board
    print "   "
    (0..@size-1).each {|num| print "#{num.to_s.rjust(2,"0")} "}
    puts
    @board.each_with_index do |row, row_index|
      print "#{row_index.to_s.rjust(2,"0")} "
      row.each_with_index do |cell, col_index|
        if cell.flagged
          print " F "
        elsif cell.revealed
          if cell.neighboring_mines == 0
            print " - "
          else
            print " #{cell.neighboring_mines} "
          end
        else
          print " ~ "
        end
      end
      puts
    end

  end

  # Error checking????
  def save_game_to_yaml
    print "Save file as:"
    filename = gets.chomp

    File.open(filename, 'w') {|f| f.write(YAML.dump(self))}

  end


end





class Cell
  attr_accessor :flagged, :mine, :neighboring_mines, :revealed
  def initialize(x_coord, y_coord)
    @flagged = false
    @mine = false
    @neighboring_mines = 0
    @revealed = false
    @posX = x_coord
    @posY = y_coord
  end

  def calculate_neighboring_mines(board, board_size)
    coordinate_adders = [-1, 0, 1]
    valid_range = (0..board_size-1)
    #print "#{[posX, posY]}"
    unless @mine # If this cell isn't a bomb

      coordinate_adders.each do |x_mod|
        coordinate_adders.each do |y_mod|
          unless x_mod == y_mod && x_mod == 0 # ignore 0,0 because it is this cell!
            neighbor_x_coord = @posX + x_mod
            neighbor_y_coord = @posY + y_mod
            if valid_range.include?(neighbor_x_coord) && valid_range.include?(neighbor_y_coord)
              # check if our neighbor indexes are out of bounds

              # check that neighbor for a mine
              if board[neighbor_x_coord][neighbor_y_coord].mine == true
                @neighboring_mines += 1
              end
            end
          end
        end
      end
      # loop through all possible neighbors
        # for each possible neighbor, if that cell actually exists on the board (eg we're not at the edge)
        # if that cell is a mine, incremenet our @neigboring_mines variable.
    end
  end

  # returns an array of neighboring cell objects
  def get_neighbors(board, board_size)
    coordinate_adders = [-1, 0, 1]
    valid_range = (0..board_size-1)
    neighbors = []

    coordinate_adders.each do |x_mod|
      coordinate_adders.each do |y_mod|

        unless x_mod == y_mod && x_mod == 0 # ignore 0,0 because it is this cell!
          neighbor_x_coord = @posX + x_mod
          neighbor_y_coord = @posY + y_mod

          if valid_range.include?(neighbor_x_coord) && valid_range.include?(neighbor_y_coord)
            neighbors << board[neighbor_x_coord][neighbor_y_coord]
          end
        end
      end
      # loop through all possible neighbors
        # for each possible neighbor, if that cell actually exists on the board (eg we're not at the edge)
        # if that cell is a bomb, incremenet our @neigboring_mines variable.
    end
    neighbors
  end
end



# SCRIPT

ms = PlayMineSweeper.new("gogo.yml")
