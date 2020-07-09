require './lib/Game.rb'

describe 'Game' do
  subject { Game.new }
  describe '#process_turn' do
    before do
      # prevent tests from writing to stdout
      allow($stdout).to receive(:write)
    end
    game = Game.new
    it 'Processes initial white pawn move correctly' do
      # move piece to target square
      white_pieces_copy = game.board.white_pieces.map(&:clone)
      white_pieces_copy = white_pieces_copy.each do |piece|
        if piece.type == 'pawn' && piece.pos_i == 6 && piece.pos_j == 4
          piece.pos_i = 5
        end
      end

      # pass move e3 to function
      allow(game).to receive(:gets).and_return("e3\n")
      game.process_turn('white')

      expect(
        # Test each piece for equality; "match_array" does not apply here
        game.board.white_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.equals(white_pieces_copy[index])
        end
      ).to eql(true)
    end
    it 'Processes initial black pawn move correctly' do
      # move piece to target square
      black_pieces_copy = game.board.black_pieces.map(&:clone)
      black_pieces_copy = black_pieces_copy.each do |piece|
        if piece.type == 'pawn' && piece.pos_i == 1 && piece.pos_j == 4
          piece.pos_i = 3
        end
      end

      # pass move e5 to function
      allow(game).to receive(:gets).and_return("e5\n")
      game.process_turn('black')

      expect(
        # Test each piece for equality; "match_array" does not apply here
        game.board.black_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.equals(black_pieces_copy[index])
        end
      ).to eql(true)
    end
    it 'Processes kingside castles correctly' do
      b = Board.new
      b.white_pieces = [
        King.new(7, 4, 'white'),
        Rook.new(7, 7, 'white'),
        Rook.new(7, 0, 'white')
      ]
      game.board = b
      allow(game).to receive(:gets).and_return("0-0\n")
      game.process_turn('white')

      castled_king = King.new(7, 6, 'white')
      castled_rook = Rook.new(7, 5, 'white')
      castled_king.moved = true
      castled_rook.moved = true
      expect(castled_king.get_attributes_array).to match_array(b.white_pieces[0].get_attributes_array)
      expect(castled_rook.get_attributes_array).to match_array(b.white_pieces[1].get_attributes_array)
    end
    it 'Processes queenside castles correctly' do
      b = Board.new
      b.white_pieces = [
        King.new(7, 4, 'white'),
        Rook.new(7, 7, 'white'),
        Rook.new(7, 0, 'white')
      ]
      game.board = b
      allow(game).to receive(:gets).and_return("0-0-0\n")
      game.process_turn('white')

      castled_king = King.new(7, 2, 'white')
      castled_rook = Rook.new(7, 3, 'white')
      castled_king.moved = true
      castled_rook.moved = true
      expect(castled_king.get_attributes_array).to match_array(b.white_pieces[0].get_attributes_array)
      expect(castled_rook.get_attributes_array).to match_array(b.white_pieces[2].get_attributes_array)
    end
  end
  describe 'Test games' do
    it "Runs through scholar's mate correctly" do
      g = Game.new
      moves = [
        'e4',
        'e5',
        'Bc4',
        'Nc6',
        'Qh5',
        'Nf6',
        'Qxf7'
      ]
      player_toggle = 0
      moves.each do |move|
        color = player_toggle == 0 ? 'white' : 'black'
        parsed_move = g.board.parse_user_move(move, color)
        parsed_move.shift
        g.board.apply_move(*parsed_move)
        player_toggle = 1 - player_toggle
      end

      expected_board = Board.new
      expected_board.black_pieces.each do |piece|
        if piece.type == 'knight'
          piece.pos_i = 2
          if piece.pos_j == 1
            piece.pos_j = 2
          else
            piece.pos_j = 5
          end
        elsif piece.type == 'pawn'
          if piece.pos_j == 4
            piece.pos_i = 3
          elsif piece.pos_j == 5
            piece.captured = true
          end
        end
      end

      expected_board.white_pieces.each do |piece|
        if piece.type == 'pawn' && piece.pos_j == 4
            piece.pos_i = 4
        elsif piece.type == 'bishop' && piece.pos_j == 5
          piece.pos_i = 4
          piece.pos_j = 2
        elsif piece.type == 'queen'
          piece.pos_i = 1
          piece.pos_j = 5
        end
      end

      expect(
        g.board.black_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.get_attributes_array == expected_board.black_pieces[index].get_attributes_array
        end
      ).to eql(true)
      expect(
        g.board.white_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.get_attributes_array == expected_board.white_pieces[index].get_attributes_array
        end
      ).to eql(true)
      expect(
        g.board.check_mate?('black')
      ).to eql(true)
    end
    it "Implements Ruy Lopez opening correctly" do
      g = Game.new
      moves = [
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bb5' 
      ]
      player_toggle = 0
      moves.each do |move|
        color = player_toggle == 0 ? 'white' : 'black'
        parsed_move = g.board.parse_user_move(move, color)
        parsed_move.shift
        g.board.apply_move(*parsed_move)
        player_toggle = 1 - player_toggle
      end

      expected_board = Board.new
      expected_board.black_pieces.each do |piece|
        if piece.type == 'knight' && piece.pos_j == 1
          piece.pos_i = 2
          piece.pos_j = 2
        elsif piece.type == 'pawn' && piece.pos_j == 4
          piece.pos_i = 3
          piece.pos_j = 4
        end
      end

      expected_board.white_pieces.each do |piece|
        if piece.type == 'pawn' && piece.pos_j == 4
            piece.pos_i = 4
        elsif piece.type == 'bishop' && piece.pos_j == 5
          piece.pos_i = 3
          piece.pos_j = 1
        elsif piece.type == 'knight' && piece.pos_j == 6
          piece.pos_i = 5
          piece.pos_j = 5
        end
      end

      expect(
        g.board.black_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.get_attributes_array == expected_board.black_pieces[index].get_attributes_array
        end
      ).to eql(true)
      expect(
        g.board.white_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.get_attributes_array == expected_board.white_pieces[index].get_attributes_array
        end
      ).to eql(true)
    end
    it "Implements Ruy Lopez opening followed by white kingside castle correctly" do
      g = Game.new
      moves = [
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bb5',
        'f6',
        '0-0'
      ]
      player_toggle = 0
      moves.each do |move|
        color = player_toggle == 0 ? 'white' : 'black'
        parsed_move = g.board.parse_user_move(move, color)
        parsed_move.shift
        if parsed_move.first == 'castle'
          g.board.apply_move(*parsed_move[1])
          g.board.apply_move(*parsed_move[2])
        else
          g.board.apply_move(*parsed_move)
        end
        player_toggle = 1 - player_toggle
      end

      expected_board = Board.new
      expected_board.black_pieces.each do |piece|
        if piece.type == 'knight' && piece.pos_j == 1
          piece.pos_i = 2
          piece.pos_j = 2
        elsif piece.type == 'pawn'
          if piece.pos_j == 4
            piece.pos_i = 3
          elsif piece.pos_j == 5
            piece.pos_i = 2
          end
        end
      end

      expected_board.white_pieces.each do |piece|
        if piece.type == 'pawn' && piece.pos_j == 4
            piece.pos_i = 4
        elsif piece.type == 'bishop' && piece.pos_j == 5
          piece.pos_i = 3
          piece.pos_j = 1
        elsif piece.type == 'knight' && piece.pos_j == 6
          piece.pos_i = 5
          piece.pos_j = 5
        elsif piece.type == 'king'
          piece.pos_j = 6
          piece.moved = true
        elsif piece.type == 'rook' && piece.pos_j == 7
          piece.pos_j = 5
          piece.moved = true
        end
      end

      expect(
        g.board.black_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.get_attributes_array == expected_board.black_pieces[index].get_attributes_array
        end
      ).to eql(true)
      expect(
        g.board.white_pieces.each_with_index.reduce(true) do |result, (piece, index)|
          result && piece.get_attributes_array == expected_board.white_pieces[index].get_attributes_array
        end
      ).to eql(true)
    end
  end
end
