require 'pry'
require 'set'

require './lib/Piece.rb'

class Board
  attr_accessor :black_pieces, :white_pieces
  def initialize
    @black_pieces = get_pieces('black')
    @white_pieces = get_pieces('white')
  end

  def get_pieces(color)
    # Return array of piece objects of given color in correct starting positions
    offset_pawns = color == 'black' ? 5 : 0
    offset_back_rank = color == 'black' ? 7 : 0
    pieces = [
      Pawn.new(6 - offset_pawns, 0, color),
      Pawn.new(6 - offset_pawns, 1, color),
      Pawn.new(6 - offset_pawns, 2, color),
      Pawn.new(6 - offset_pawns, 3, color),
      Pawn.new(6 - offset_pawns, 4, color),
      Pawn.new(6 - offset_pawns, 5, color),
      Pawn.new(6 - offset_pawns, 6, color),
      Pawn.new(6 - offset_pawns, 7, color),
      Rook.new(7 - offset_back_rank, 0, color),
      Rook.new(7 - offset_back_rank, 7, color),
      Knight.new(7 - offset_back_rank, 1, color),
      Knight.new(7 - offset_back_rank, 6, color),
      Bishop.new(7 - offset_back_rank, 2, color),
      Bishop.new(7 - offset_back_rank, 5, color),
      Queen.new(7 - offset_back_rank, 3, color),
      King.new(7 - offset_back_rank, 4, color)
    ]
    pieces
  end

  def to_s
    # Return human-readable board string
    rows = []
    file_id_arr = %w'a b c d e f g h'
    rows.push('  ' + file_id_arr.join(' '))
    board = get_board
    board.each_with_index do |row, index|
      row_id = 8 - index
      row_arr = [row_id]
      row.each do |square|
        square = square.nil? ? ' ' : square.ascii_code
        row_arr.push("#{square}")
      end
      row_arr.push(row_id)
      rows.push(row_arr.join('|'))
    end
    rows.push('  ' + file_id_arr.join(' '))
    rows.join("\n")
  end

  def get_board
    # Return array of arrays representing the rows of the chess board, with pieces at correct locations
    nil_row = [nil, nil, nil, nil, nil, nil, nil, nil]
    board = []
    8.times do
      board << [*nil_row]
    end
    (@black_pieces + @white_pieces).each do |piece|
      next if piece.captured
      board[piece.pos_i][piece.pos_j] = piece
    end
    board
  end

  def parse_user_move(move_str, color='black')
    # Return an array with the result of the parsed move
    # Return array elements:
    #  0 - boolean indicating whether the move is valid or not
    #  1 - if not valid, the error message; else, the Piece object that will make indicated move
    #  2 - the i coordinate for the target square of the move
    #  3 - the j coordinate for the target square of the move
    # Note that if the given move is a valid castle, array elements 1 and 2 of the return array will be:
    #  1 - Same as array elements 1-3 listed above, for the king
    #  2 - Same as array elements 1-3 listed above, for the rook piece involved in castle

    # Check if in valid algebraic notation
    algebraic_pattern = /(?:[KNRQB](?:[a-h]?[1-8]?)|[a-h])?x?[a-h][1-8]|0-0(?:-0)?/
    unless String(move_str.match(algebraic_pattern)) == move_str  # needs to match entire string
      return [false, "The given string is not in proper algebraic notation."]
    end

    if move_str == '0-0' || move_str == '0-0-0'
      return process_castle(move_str, color)
    end

    # If valid algebraic notation, parse parts
    move_arr = move_str.split('')
    piece_str = move_arr[0]
    rank = move_arr[-2]
    file = move_arr[-1].to_i

    # captures
    if move_arr.include?('x')
      disambig1 = move_arr[1] == 'x' ? '' : move_arr[1]
      disambig2 = move_arr[2].ord >= 48 && move_arr[2].ord <= 57 ? move_arr[2] : '' # if it's a digit 0-9
    else
      disambig1 = move_arr.length == 4 || move_arr.length == 5 ? move_arr[1] : ''
      disambig2 = move_arr.length == 5 ? move_arr[2] : ''
    end

    # Check if there exists a piece of given type that can move to indicated square
    piece = get_piece(piece_str, rank, file, disambig1, disambig2, color)

    piece
  end

  def process_castle(castle_str, color)
    # Return true if valid castle
    kingside = castle_str == '0-0'
    queenside = !kingside

    pieces = color == 'black' ? @black_pieces : @white_pieces

    rook_i = color == 'black' ? 0 : 7
    rook_j = kingside ? 7 : 0
    files_bw = kingside ? [5, 6] : [1, 2, 3]
    king = pieces.filter { |piece| piece.type == 'king' }.first
    king_move_j = kingside ? 6 : 2

    king_moved = pieces.filter { |piece| piece.type == 'king' }.first.moved
    rooks_valid = pieces.filter do |piece|
      piece.type == 'rook' && 
      !piece.captured &&
      !piece.moved &&
      piece.pos_i == rook_i &&
      piece.pos_j == rook_j
    end.length == 1
    pieces_blocking = pieces.filter do |piece|
      piece.pos_i == rook_i && files_bw.include?(piece.pos_j)
    end.length > 0
    if !pieces_blocking
      move_thru_check = (1..2).reduce(false) do |result, j_offset|
        j_offset = king.pos_j < king_move_j ? j_offset : j_offset * -1
        result || creates_self_check?(king, rook_i, king.pos_j + j_offset)
      end
    else
      move_thru_check = false
    end

    if king_moved || !rooks_valid || pieces_blocking || move_thru_check
      return [false, "Castle not valid"]
    else
      rook = pieces.filter { |piece| piece.type == 'rook' && piece.pos_i == rook_i && piece.pos_j == rook_j }.first
      
      rook_move_j = kingside ? 5 : 3
      return [true, "castle", [king, rook_i, king_move_j], [rook, rook_i, rook_move_j]]
    end
  end

  def valid_pawn_capture?(start_i, start_j, target_i, target_j, opp_pieces)
    # Does not check for en passant captures, just diagonal captures
    capture_pieces = opp_pieces.filter { |piece| piece.pos_i == target_i && piece.pos_j == target_j }
    i_dif = (start_i - target_i).abs
    j_dif = (start_j - target_j).abs
    return capture_pieces.length > 0 &&  i_dif == 1 && j_dif == 1
  end

  def create_piece(piece_type, i, j, color)
    # Return new instance of Piece of given piece type and color in position [i, j]
    case true
    when piece_type == 'R'
      return Rook.new(i, j, color)
    when piece_type == 'N'
      return Knight.new(i, j, color)
    when piece_type == 'B'
      return Bishop.new(i, j, color)
    when piece_type == 'Q'
      return Queen.new(i, j, color)
    when piece_type == 'K'
      return King.new(i, j, color)
    else
      return Pawn.new(i, j, color)
    end
  end

  def get_piece(piece_type, rank, file, disambig1, disambig2, color='black')
    # Return an array with the result of the parsed move.
    # Return array elements:
    #  0 - boolean indicating whether the move is valid or not
    #  1 - if not valid, the error message; else, the Piece object that will make indicated move
    #  2 - the i coordinate for the target square of the move
    #  3 - the j coordinate for the target square of the move
    # Note that if the given move is a valid castle, array elements 1 and 2 of the return array will be:
    #  1 - Same as array elements 1-3 listed above, for the king
    #  2 - Same as array elements 1-3 listed above, for the rook piece involved in castle

    i = 8 - file       # convert 1-8 to 0-7. The order is switched
    j = rank.ord - 97  # convert a-h to 0-7
    pieces = color == 'black' ? @black_pieces : @white_pieces
    opp_pieces = color == 'white' ? @black_pieces : @white_pieces

    piece = create_piece(piece_type, i, j, color)
    if piece.type == 'pawn'
      disambig1 = piece_type
    end

    # Populate pos_pieces set with pieces that can make a move to [i, j]
    pos_pieces = Set.new  # Set is used instead of array bc we only want unique pieces
    pieces.each do |pos_piece|
      if !pos_piece.captured &&
         pos_piece.type == piece.type && 
         pos_piece.get_poss_moves.include?([i, j]) &&
         (piece.type != 'pawn' ||
            (piece.type == 'pawn' &&
              (pos_piece.pos_j == j ||  # Move is forward
               valid_pawn_capture?(pos_piece.pos_i, pos_piece.pos_j, i, j, opp_pieces) # Move is diagonal and makes a valid capture
              )
            )
         )
        pos_pieces << pos_piece
      end
    end

    if pos_pieces.length.zero?
      return [false, "No legal move to square indicated"]
    end

    # handle disambiguation
    if pos_pieces.length > 1
      disambig_i, disambig_j = disambig(disambig1, disambig2)
      pos_pieces = pos_pieces.filter { |pos_piece|
        (disambig_i == '' || (disambig_i != '' && pos_piece.pos_i == disambig_i)) &&
        (disambig_j == '' || (disambig_j != '' && pos_piece.pos_j == disambig_j))
      }
      if pos_pieces.length > 1
        return [false, "Multiple pieces can perform indicated move, disambiguation needed"]
      elsif pos_pieces.length == 0
        return [false, "Provided disambiguation does not match any pieces on board"]
      end
    end

    # test for validity on board
    start_piece = pos_pieces.to_a[0]
    if move_blocked?(start_piece, i, j)
      return [false, "Move blocked by one or more pieces on the board"]
    elsif creates_self_check?(start_piece, i, j)
      return [false, "Move puts player in check, please choose another move"]
    end

    [true, start_piece, i, j]
  end

  def creates_self_check?(move_piece, i, j)
    # Return true if moving piece move_piece to square [i, j] will create a check for current player
    board = apply_move_to_copy(move_piece, i, j)
    board.check?(move_piece.color)
  end

  def check?(color)
    # Return true if color is in check
    opp_pieces = color == 'black' ? @white_pieces : @black_pieces # get opposing pieces
    pieces = color == 'black' ? @black_pieces : @white_pieces   # get player pieces

    king = pieces.filter { |piece| piece.type == 'king' }[0]
    king_i = king.pos_i
    king_j = king.pos_j

    opp_pieces.each do |piece|
      next if piece.captured
      if piece.get_poss_moves.include?([king_i, king_j]) && !move_blocked?(piece, king_i, king_j)
        return true
      end
    end
    false
  end

  def check_mate?(color)
    # Return true if color is in mate

    # test if king is currently in check
    in_check = check?(color)
    return false unless in_check

    opp_pieces = color == 'black' ? @white_pieces : @black_pieces # get opposing pieces
    pieces = color == 'black' ? @black_pieces : @white_pieces   # get player pieces

    king = pieces.filter { |piece| piece.type == 'king' }[0]
    king_i = king.pos_i
    king_j = king.pos_j

    # test if king can make moves to get out of check
    king_moves = king.get_poss_moves.filter { |move| !move_blocked?(king, move.first, move.last) }
    king_moves.each do |move|
      return false unless creates_self_check?(king, move.first, move.last)
    end

    # test if other pieces can block check or remove checking piece
    pieces.each do |piece|
      moves = piece.get_poss_moves.filter { |move| !move_blocked?(piece, move.first, move.last) }
      moves.each do |move|
        return false unless creates_self_check?(piece, move.first, move.last)
      end
    end

    true
  end

  def apply_move_to_copy(move_piece, i, j)
    # Apply move to piece and return result as new Board instance, leaving original unmodified

    # get copy of pieces arrays
    opp_pieces = move_piece.color == 'black' ? @white_pieces.map(&:clone) : @black_pieces.map(&:clone)
    pieces = move_piece.color == 'black' ? @black_pieces.map(&:clone) : @white_pieces.map(&:clone)

    # grab move_piece equivalent from copied arrays
    move_piece = pieces.select { |piece|
      move_piece.type == piece.type && move_piece.pos_i == piece.pos_i && move_piece.pos_j == piece.pos_j
    }[0]

    # handle en passant captures
    if move_piece.type == 'pawn' &&
        ((move_piece.pos_i == 1 && move_piece.color == 'black') ||
         (move_piece.pos_i == 6 && move_piece.color == 'white'))
      captured_piece_i = move_piece.color == 'black' ? 2 : 5
      passant_captured_piece = opp_pieces.select { |piece|
        piece.pos_i == captured_piece_i && (piece.pos_j - j).abs == 1
      }[0]
    end

    # adjust piece array copies to reflect move
    move_piece.pos_i = i
    move_piece.pos_j = j

    # capture opposing piece on target square if one exists
    move_captured_piece = opp_pieces.select { |piece|
      piece.pos_i == i && piece.pos_j == j && !piece.captured
    }[0]

    if move_captured_piece
      move_captured_piece.captured = true
    elsif passant_captured_piece
      passant_captured_piece.captured = true
    end

    # update moved boolean for rooks and kings
    if move_piece.type == 'king' || move_piece.type == 'rook'
      move_piece.moved = true
    end

    # create new board instance reflecting move
    board = Board.new
    board.white_pieces = move_piece.color == 'white' ? pieces : opp_pieces
    board.black_pieces = move_piece.color == 'black' ? pieces : opp_pieces

    board
  end

  def apply_move(move_piece, i, j)
    # Apply move to piece and adjust both pieces arrays

    board = apply_move_to_copy(move_piece, i, j)
    @black_pieces = board.black_pieces
    @white_pieces = board.white_pieces
  end

  def move_blocked?(piece, i, j)
    start_i, start_j = [piece.pos_i, piece.pos_j]
    board = get_board
    unless board[i][j].nil?
      unless board[i][j].color != piece.color
        # If target square is occupied by piece of same color, move is blocked
        return true
      end
    end

    if piece.type == 'knight'
      # Knights can jump directly to target square, so move is not blocked
      return false
    elsif piece.type == 'pawn'
      if j == piece.pos_j
        if (i - start_i).abs == 2
          int_i = i > start_i ? start_i + 1 : start_i - 1
          return true unless board[int_i][j].nil?
        end
        return !board[i][j].nil?
      else
        return false
      end
    else
      # Check path of move for pieces of either color; if pieces in path, move is blocked
      move_i = start_i
      move_j = start_j
      loop do
        move_i = i > start_i ? move_i + 1 : i < start_i ? move_i - 1 : i
        move_j = j > start_j ? move_j + 1 : j < start_j ? move_j - 1 : j
        break if move_i == i && move_j == j
        return true unless board[move_i][move_j].nil?
      end
    end

    false
  end

  def disambig(disambig1, disambig2)
    # Return [i, j] coordinates that line up with given disambiguation strings
    disambig1 = disambig1 == '' ? -1 : disambig1  # Prevent error when taking ord of empty string
    disambig2 = disambig2 == '' ? -1 : disambig2
    disambig_j = disambig1.ord >= 97 && disambig1.ord <= 104 ? disambig1.ord - 97 : ''
    disambig_i = disambig1.ord >= 49 && disambig1.ord <= 56  ? 56 - disambig1.ord :
                 disambig2.ord >= 49 && disambig2.ord <= 56  ? 56 - disambig2.ord : ''
    [disambig_i, disambig_j]
  end
end
