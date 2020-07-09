require './lib/Board.rb'

describe 'Board' do
  subject { Board.new }
  describe '#check?' do
    it 'identifies check correctly' do
      b = Board.new
      b.white_pieces = [
        Rook.new(1, 0, 'white')
      ]
      b.black_pieces = [
        King.new(0, 0, 'black')
      ]
      expect(b.check?('black')).to eql(true)
    end
  end
  describe '#check_mate?' do
    it 'identifies check mate correctly' do
      b = Board.new
      b.white_pieces = [
        Rook.new(2,0,'white'),
        Queen.new(1,2,'white')
      ]
      b.black_pieces = [
        King.new(0, 0, 'black')
      ]
      expect(b.check_mate?('black')).to eql(true)
    end
    it 'returns false when king can move to escape mate' do
      b = Board.new
      b.white_pieces = [
        Rook.new(2, 0, 'white')
      ]
      b.black_pieces = [
        King.new(0, 0, 'black')
      ]
      expect(b.check_mate?('black')).to eql(false)
    end
    it 'returns false when piece can block mate' do
      b = Board.new
      b.white_pieces = [
        Rook.new(2, 1, 'white'),
        Queen.new(2, 0, 'white')
      ]
      b.black_pieces = [
        King.new(0, 0, 'black'),
        Bishop.new(0, 1, 'black')
      ]
      expect(b.check_mate?('black')).to eql(false)
    end
    it 'returns false when piece can capture checking piece' do
      b = Board.new
      b.white_pieces = [
        Rook.new(2, 1, 'white'),
        Queen.new(2, 0, 'white')
      ]
      b.black_pieces = [
        King.new(0,0,'black'),
        Bishop.new(0,2,'black')
      ]
      expect(b.check_mate?('black')).to eql(false)
    end
  end
  describe '#parse_user_move' do
    describe 'Rejects invalid moves' do
      it 'Rejects moves not in proper algebraic notation' do
        expect(subject.parse_user_move('jack')).to match_array([false, "The given string is not in proper algebraic notation."])
        expect(subject.parse_user_move('x8')).to match_array([false, "The given string is not in proper algebraic notation."])
        expect(subject.parse_user_move('Kxb10')).to match_array([false, "The given string is not in proper algebraic notation."])
      end
      it 'Rejects moves not possible considering position only on board' do
        expect(subject.parse_user_move('Rb4')).to match_array([false, "No legal move to square indicated"])
      end
      it 'Rejects moves missing disambiguation' do
        b = Board.new
        b.white_pieces = []
        b.black_pieces = [
          Knight.new(7, 0, 'black'),
          Knight.new(7, 2, 'black')
        ]
        expect(b.parse_user_move('Nb3')).to match_array([false, "Multiple pieces can perform indicated move, disambiguation needed"])
        expect(b.parse_user_move('Nfb3')).to match_array([false, "Provided disambiguation does not match any pieces on board"])
      end
      it 'Rejects moves that are blocked by other pieces on the board' do
        expect(subject.parse_user_move('Ra4')).to match_array([false, "Move blocked by one or more pieces on the board"])
        expect(subject.parse_user_move('Bb7')).to match_array([false, "Move blocked by one or more pieces on the board"])
        expect(subject.parse_user_move('Ba6')).to match_array([false, "Move blocked by one or more pieces on the board"])
      end
      it 'Rejects moves that put the player in check' do
        b = Board.new
        b.white_pieces = [
          Rook.new(0, 0, 'white')
        ]
        b.black_pieces = [
          King.new(7, 0, 'black'),
          Rook.new(6, 0, 'black')
        ]
        expect(b.parse_user_move('Rb2')).to match_array([false, "Move puts player in check, please choose another move"])
      end
      it 'Rejects castles that move through check' do
        b = Board.new
        b.black_pieces = [
          Rook.new(0, 5, 'black'),
          Rook.new(0, 3, 'black')
        ]
        b.white_pieces = [
          King.new(7, 4, 'white'),
          Rook.new(7, 7, 'white'),
          Rook.new(7, 0, 'white')
        ]
        move_result = b.parse_user_move('0-0', 'white')
        expect(move_result[0]).to eql(false)
        expect(move_result[1]).to eql("Castle not valid")

        move_result = b.parse_user_move('0-0-0', 'white')
        expect(move_result[0]).to eql(false)
        expect(move_result[1]).to eql("Castle not valid")
      end
      it 'Rejects castles where king has already moved' do
        b = Board.new
        b.white_pieces = [
          King.new(7, 4, 'white'),
          Rook.new(7, 7, 'white'),
          Rook.new(7, 0, 'white')
        ]
        b.apply_move(b.white_pieces[0], 7, 3)
        move_result = b.parse_user_move('0-0', 'white')
        expect(move_result[0]).to eql(false)
        expect(move_result[1]).to eql("Castle not valid")
      end
      it 'Rejects castles where rook has already moved' do
        b = Board.new
        b.white_pieces = [
          King.new(7, 4, 'white'),
          Rook.new(7, 7, 'white'),
          Rook.new(7, 0, 'white')
        ]
        b.apply_move(b.white_pieces[1], 7, 3)
        move_result = b.parse_user_move('0-0', 'white')
        expect(move_result[0]).to eql(false)
        expect(move_result[1]).to eql("Castle not valid")
      end
      it 'Rejects castles where pieces are in the way' do
        b = Board.new
        b.white_pieces = [
          King.new(7, 4, 'white'),
          Rook.new(7, 7, 'white'),
          Rook.new(7, 0, 'white'),
          Bishop.new(7, 5, 'white')
        ]
        move_result = b.parse_user_move('0-0', 'white')
        expect(move_result[0]).to eql(false)
        expect(move_result[1]).to eql("Castle not valid")
      end
    end
    describe 'Parses valid moves correctly' do
      it 'Parses pawn non-capture move correctly' do
        b = Board.new
        move_result = b.parse_user_move('e4', 'white')
        expect(move_result[0]).to eql(true)
        expected_piece = Pawn.new(6, 4, 'white')
        expect(move_result[1].get_attributes_array).to match_array(expected_piece.get_attributes_array)
        expect([move_result[2], move_result[3]]).to match_array([4, 4])
      end
      it 'Parses pawn capture move correctly' do
        b = Board.new
        b.black_pieces = [
          Pawn.new(5, 4, 'black')
        ]
        move_result = b.parse_user_move('dxe3', 'white')
        expect(move_result[0]).to eql(true)

        expected_piece = Pawn.new(6, 3, 'white')
        expect(move_result[1].get_attributes_array).to match_array(expected_piece.get_attributes_array)
        expect([move_result[2], move_result[3]]).to match_array([5, 4]) # target [i, j] coordinates
      end
      it 'Parses non-pawn non-capture move correctly' do
        b = Board.new
        move_result = b.parse_user_move('Nc3', 'white')
        expect(move_result[0]).to eql(true)
        expected_piece = Knight.new(7, 1, 'white')
        expect(move_result[1].get_attributes_array).to match_array(expected_piece.get_attributes_array)
        expect([move_result[2], move_result[3]]).to match_array([5, 2])
      end
      it 'Parses non-pawn capture move correctly' do
        b = Board.new
        b.black_pieces = [
          Pawn.new(5, 2, 'black')
        ]
        move_result = b.parse_user_move('Nxc3', 'white')
        expect(move_result[0]).to eql(true)

        expected_piece = Knight.new(7, 1, 'white')
        expect(move_result[1].get_attributes_array).to match_array(expected_piece.get_attributes_array)
        expect([move_result[2], move_result[3]]).to match_array([5, 2])
      end
      it 'Parses queenside castles correctly' do
        b = Board.new
        b.white_pieces = [
          King.new(7, 4, 'white'),
          Rook.new(7, 0, 'white')
        ]
        move_result = b.parse_user_move('0-0-0', 'white')
        expect(move_result[0]).to eql(true)
        expect(move_result[1]).to eql('castle')
        king_array = move_result[2]
        rook_array = move_result[3]

        expected_king = King.new(7, 4, 'white')
        expect(king_array.first.get_attributes_array).to match_array(expected_king.get_attributes_array)
        expect([king_array[1], king_array[2]]).to match_array([7, 2])

        expected_rook = Rook.new(7, 0, 'white')
        expect(rook_array.first.get_attributes_array).to match_array(expected_rook.get_attributes_array)
        expect([rook_array[1], rook_array[2]]).to match_array([7, 3])
      end
      it 'Parses kingside castles correctly' do
        b = Board.new
        b.white_pieces = [
          King.new(7, 4, 'white'),
          Rook.new(7, 7, 'white')
        ]
        move_result = b.parse_user_move('0-0', 'white')
        expect(move_result[0]).to eql(true)
        expect(move_result[1]).to eql('castle')
        king_array = move_result[2]
        rook_array = move_result[3]

        expected_king = King.new(7, 4, 'white')
        expect(king_array.first.get_attributes_array).to match_array(expected_king.get_attributes_array)
        expect([king_array[1], king_array[2]]).to match_array([7, 6])

        expected_rook = Rook.new(7, 7, 'white')
        expect(rook_array.first.get_attributes_array).to match_array(expected_rook.get_attributes_array)
        expect([rook_array[1], rook_array[2]]).to match_array([7, 5])
      end
      describe 'Parses file-disambiguated moves correctly' do
        b = Board.new
        b.white_pieces = [
          Knight.new(7, 0, 'white'),
          Knight.new(7, 2, 'white'),
          King.new(7, 7, 'white') # necessary because move parser test for check
        ]
        it 'Identifies correct knight' do
          move_result = b.parse_user_move('Nab3', 'white')
          expect(move_result[0]).to eql(true)
          expect(move_result[1].get_attributes_array).to match_array(b.white_pieces[0].get_attributes_array)
          expect([move_result[2], move_result[3]]).to match_array([5, 1])
        end
        it 'Works when indicating other knight' do
          move_result = b.parse_user_move('Ncb3', 'white')
          expect(move_result[0]).to eql(true)
          expect(move_result[1].get_attributes_array).to match_array(b.white_pieces[1].get_attributes_array)
          expect([move_result[2], move_result[3]]).to match_array([5, 1])
        end
        it 'Works with captures' do
          b.black_pieces = [
            Pawn.new(5, 1, 'black')
          ]
          move_result = b.parse_user_move('Naxb3', 'white')
          expect(move_result[0]).to eql(true)
          expect(move_result[1].get_attributes_array).to match_array(b.white_pieces[0].get_attributes_array)
          expect([move_result[2], move_result[3]]).to match_array([5, 1])
        end
      end
      describe 'Parses rank-disambiguated moves correctly' do
        b = Board.new
        b.white_pieces = [
          Knight.new(7, 0, 'white'),
          Knight.new(5, 0, 'white'),
          King.new(7, 7, 'white') # necessary because move parser test for check
        ]
        it 'Identifies correct knight' do
          move_result = b.parse_user_move('N1c2', 'white')
          expect(move_result[0]).to eql(true)
          expect(move_result[1].get_attributes_array).to match_array(b.white_pieces[0].get_attributes_array)
          expect([move_result[2], move_result[3]]).to match_array([6, 2])
        end
        it 'Works when indicating other knight' do
          move_result = b.parse_user_move('N3c2', 'white')
          expect(move_result[0]).to eql(true)
          expect(move_result[1].get_attributes_array).to match_array(b.white_pieces[1].get_attributes_array)
          expect([move_result[2], move_result[3]]).to match_array([6, 2])
        end
        it 'Works with captures' do
          b.black_pieces = [
            Pawn.new(6, 2, 'black')
          ]
          move_result = b.parse_user_move('N3xc2', 'white')
          expect(move_result[0]).to eql(true)
          expect(move_result[1].get_attributes_array).to match_array(b.white_pieces[1].get_attributes_array)
          expect([move_result[2], move_result[3]]).to match_array([6, 2])
        end
      end
    end
  end
  describe '#apply_move' do
    it 'Applies pawn non-capture correctly' do
      b = Board.new
      b.white_pieces = [
        Pawn.new(6, 3, 'white')
      ]
      b.apply_move(b.white_pieces[0], 4, 3)
      expect(b.white_pieces[0].pos_i).to eql(4)
      expect(b.white_pieces[0].pos_j).to eql(3)
    end
    it 'Applies pawn diagonal capture correctly' do
      b = Board.new
      b.black_pieces = [
        Pawn.new(5, 4, 'black')
      ]
      b.white_pieces = [
        Pawn.new(6, 3, 'white')
      ]
      b.apply_move(b.white_pieces[0], 5, 4)
      expect(b.black_pieces[0].captured).to eql(true)
      expect(b.white_pieces[0].pos_i).to eql(5)
      expect(b.white_pieces[0].pos_j).to eql(4)
    end
    it 'Applies pawn en-passant capture correctly' do
      b = Board.new
      b.black_pieces = [
        Pawn.new(5, 4, 'black')
      ]
      b.white_pieces = [
        Pawn.new(6, 3, 'white')
      ]
      b.apply_move(b.white_pieces[0], 4, 3)
      expect(b.black_pieces[0].captured).to eql(true)
      expect(b.white_pieces[0].pos_i).to eql(4)
      expect(b.white_pieces[0].pos_j).to eql(3)
    end
  end
end