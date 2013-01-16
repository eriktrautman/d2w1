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
      rescue Errno::ENOENT => e
        puts "Could not parse YAML: #{e.message}"
        m = MineSweeper.new
      end
    end
    m.play
  end

end

class MineSweeper

  VALID_MOVE_TYPES = ["f", "u", "r"]

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

  def play

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

  def valid_coords?(coords) # elegant code here
    valid_range = (0..@size-1)
    valid_range.include?(coords[0]) && valid_range.include?(coords[1])
  end

  def get_user_move_type
    move_type = ""
    puts "\nPick a valid move type, "
    puts "e.g. 'f' to place a flag or 'r' to reveal cell"
    puts "'s' will save the board and 'q' will quit the game."
    until VALID_MOVE_TYPES.include?(move_type)
      move_type = gets.chomp.downcase
      if move_type == "s"
        save_game_to_yaml
      elsif move_type == "q"
        exit
      end
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
  def figure_out_cell_numbers # nitpicky, but methode name could be more indicative of it's goal: 'get_neighboring_mines'
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

ms = PlayMineSweeper.new("go0go.yml")

# #require 'debugger'
# class Board
#   DELTAS = [[1, 1],
#   [1, 0],
#   [1, -1],
#   [-1, 1],
#   [-1, 0],
#   [-1, -1],
#   [0, 1],
#   [0, -1]
#   ]

#   attr_reader :game_board

#   def initialize(size)
#     @game_board = build_board(size)
#   end

#   def build_board(size)
#     board = place_bombs(blank_board(size))
#     visit_adjacents(board) do |item, adjacent_item| 
#       item.adj_bombs += 1 if adjacent_item.bomb == true
#     end

#   end

#   def blank_board(size)
#     empty_board = []
#     size.times do |row_index|
#       empty_row = []
#       size.times { |column_index| empty_row << BoardPosition.new(row_index, column_index) }
#       empty_board << empty_row
#     end
#     empty_board
#   end

#   def place_bombs(board)
#     num_of_bombs(board).times do
#       row, column = choose_bomb_location(board)
#       while board[row][column].bomb == true
#         row, column = choose_bomb_location(board)
#       end
#       board[row][column].bomb = true
#     end
#     board
#   end

#   def num_of_bombs(board)
#     if board.size == 9
#       return 10
#     elsif board.size == 16
#       return 40
#     end
#   end

#   def choose_bomb_location(board)
#     row = rand(0..board.length - 1)
#     column = rand(0..board.length - 1)
#     [row, column]
#   end

# #displays board for testing purposes
#   # def display_bomb_board
#   #   @game_board.each do |row|
#   #     row.each do |item|
#   #       print "#{item.adj_bombs}|#{item.bomb} "
#   #     end
#   #     puts ""
#   #   end
#   #   return nil
#   # end

#   def adjacents(row, column, board)
#     adjacents_array = []

#     DELTAS.each do |delta|
#       new_row = row + delta[0]
#       new_column = column + delta[1]
#       if (0..board.size - 1).include?(new_row) && (0..board.size - 1).include?(new_column)
#         adjacents_array << board[new_row][new_column]
#       end
#     end
#     adjacents_array
#   end

#   def visit_adjacents(board, &set_adj)
#     board.each_with_index do |row, row_index|
#       row.each_with_index do |item, column_index|

#         adjacents_array = adjacents(row_index, column_index, board)
#         adjacents_array.each do |adjacent_item|
#           set_adj.call(item, adjacent_item)
#         end
#       end
#     end
#   end

# end

# class BoardPosition
#   attr_accessor :bomb, :visited, :adj_bombs, :flag, :row, :column

#   def initialize(row, column, bomb=false, visited=false, adj_bombs=0, flag=false)
#     @bomb = bomb
#     @visited = visited
#     @adj_bombs = adj_bombs
#     @flag = flag
#     @row = row
#     @column = column
#   end

# end

# class Game
#   attr_accessor :board

#   def initialize(size)
#     @size = size
#     #change this to accept variable board size later
#     @board = Board.new(@size)
#   end

#   def check_reveal_move(row, column)
#     current_position = @board.game_board[row][column]

#     if current_position.flag
#       return
#     elsif current_position.adj_bombs == 0 && !current_position.visited
#       current_position.visited = true

#       adjacent_array = @board.adjacents(row, column, @board.game_board)
#       adjacent_array.each { |item| check_adjacents_zero(item.row, item.column) }

#     else
#       current_position.visited = true
#       return
#     end
#   end

#   def lose?(row, column)
#     if @board.game_board[row][column].bomb
#       puts "You lose!"
#       return true
#     else
#       return false
#     end
#   end

#   def win?
#     #checks to see if all bombs are flagged and no flags on not-bombs
#     total_not_bomb = []
#     visited_not_bomb = []
#     @board.game_board.each do |row|
#       row.each do |item|
#         total_not_bomb << item if !item.bomb
#         visited_not_bomb << item if !item.bomb && item.visited
#       end
#     end

#     if visited_not_bomb.length == total_not_bomb.length
#       puts "Congratulations! You win."
#       display_game
#       return true
#     else
#       return false
#     end
#   end

#   def display_game
#     print "  "
#     (0..@size).each {|num| print "  #{num} "}
#     puts ""
#     row_num = 0

#     @board.game_board.each do |row|
#       print "#{row_num}: "
#       row.each do |item|

#         if item.flag == true
#           print "|f| "
#         elsif item.visited == true
#           print "|#{item.adj_bombs}| "
#         else
#           print "|*| "
#         end
#       end

#       puts ""
#       row_num += 1
#     end
#     return nil
#   end

#   def process_user_move(move_string)
#     move_array = move_string.split
#     row_index = move_array[1].to_i
#     column_index = move_array[2].to_i

#     if move_array[0] == "r"
#       reveal(row_index, column_index)
#     elsif move_array[0] == "f"
#       flag_space(row_index, column_index)
#     end
#   end

#   def reveal(row_index, column_index)
#     if @board.game_board[row_index][column_index].flag
#       puts "This position is flagged"
#       return
#     elsif lose?(row_index, column_index)
#       @lose_game = true
#     else
#       check_reveal_move(row_index, column_index)
#     end
#   end

#   def flag_space(row_index, column_index)
#     if @board.game_board[row_index][column_index].flag
#       puts "Unflagging position #{row_index}, #{column_index}"
#       @board.game_board[row_index][column_index].flag = false
#     elsif @board.game_board[row_index][column_index].visited
#       puts "Can't flag a visited square."
#     else
#       puts "Adding flag to position #{row_index}, #{column_index}"
#       @board.game_board[row_index][column_index].flag = true
#     end
#   end


#   def play
#     player = User.new

#     keep_playing = true
#     while keep_playing
#       display_game
#       move = player.get_move
#       process_user_move(move)
#       if win?
#         keep_playing = false
#       elsif @lose_game
#         keep_playing = false
#       end
#     end

#   end

# end

# class User

#   def get_move
#     print "Your move please: "
#     user_move = gets.chomp.downcase
#   end
# end

# def start
#   puts "What size game square would you like?"
#   puts "16 or 9"
#   print "> "
#   game_board_size = gets.chomp.to_i
#   game = Game.new(game_board_size)
#   game.play
# end
