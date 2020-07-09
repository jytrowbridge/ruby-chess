require './lib/Board.rb'

class Game
  attr_accessor :board
  def initialize
    @board = Board.new
  end

  def play
    player_toggle = 0
    puts @board.to_s
    loop do
      player_color = player_toggle == 0 ? 'white' : 'black'
      opp_color = player_toggle == 0 ? 'black' : 'white'
      process_turn(player_color)
      if @board.check_mate?(opp_color)
        puts "Check mate, #{player_color} wins!"
        return
      elsif @board.check?(opp_color)
        puts "Check!"
      end
      player_toggle = 1 - player_toggle
    end
  end

  def process_turn(color)
    move = gets.chomp
    parsed_move = @board.parse_user_move(move, color)

    if parsed_move[0]
      parsed_move.shift   # remove first value of parsed_move, the boolean indicator of success
      if parsed_move.first == 'castle'
        @board.apply_move(*parsed_move[1])
        @board.apply_move(*parsed_move[2])
      else
        @board.apply_move(*parsed_move)  # parsed_move item 1 is the piece object; items 2 and 3 are the i, j coordinates
      end
      puts @board.to_s
    else
      puts parsed_move[1]
      process_turn(color)
    end
  end
end