class Piece
  attr_reader :ascii_code, :type, :color
  attr_accessor :pos_i, :pos_j,  :captured
  def initialize(i, j, color)
    @pos_i = i
    @pos_j = j
    @color = color
    @ascii_code = nil
    @type = nil
    @captured = false
  end

  def piece_valid_move?(i, j)
    # check if valid on board:
    (i >= 0) && (i <= 7) && (j >= 0) && (j <= 7)
  end

  def equals(piece)
    @pos_i == piece.pos_i &&
    @pos_j == piece.pos_j &&
    @color == piece.color &&
    @ascii_code == piece.ascii_code &&
    @type == piece.type &&
    @captured == piece.captured
  end

  def get_attributes_array
    return [
      @pos_i,
      @pos_j,
      @color,
      @ascii_code,
      @type,
      @captured
    ]
  end
end

class Pawn < Piece
  def initialize(i, j, color)
    super(i, j, color)
    @ascii_code = color == 'white' ? "\u265F" : "\u2659"
    @type = "pawn"
  end

  def piece_valid_move?(i, j)
    valid_generic = super(i, j)

    color_flip = color == 'black' ? 1 : -1
    j_dif = (j - pos_j).abs
    in_starting_pos = (color == 'black' && pos_i == 1) || (color == 'white' && pos_i == 6)
    return valid_generic && (
      (i == pos_i + (1 * color_flip) && (j_dif == 0 || j_dif == 1)) ||
      (in_starting_pos && i == pos_i + (2 * color_flip) && j_dif == 0)
    )
  end
  
  def get_poss_moves()
    moves = []
    color_flip = color == 'black' ? 1 : -1
    moves.push([pos_i + (1 * color_flip), pos_j - 1])
    moves.push([pos_i + (1 * color_flip), pos_j + 1])
    moves.push([pos_i + (1 * color_flip), pos_j])
    if (color == 'black' && pos_i == 1) || (color == 'white' && pos_i == 6)
      moves.push([pos_i + (2 * color_flip), pos_j])
    end
    moves.filter { |move| move.first >= 0 && move.last >= 0 && move.first <= 7 && move.last <= 7 }
  end
end

class Rook < Piece
  attr_accessor :moved
  def initialize(i, j, color)
    super(i, j, color)
    @ascii_code = color == 'white' ? "\u265C" : "\u2656"
    @type = "rook"
    @moved = false
  end

  def get_poss_moves()
    moves = []
    (0..7).each do |x|
      moves.push([@pos_i, x]) if x != @pos_j
      moves.push([x, @pos_j]) if x != @pos_i
    end
    moves
  end

  def piece_valid_move?(i, j)
    valid_generic = super(i, j)

    valid_generic && ((i == @pos_i && j != @pos_j) || (j == @pos_j && i != @pos_i))
  end
end

class Knight < Piece
  def initialize(i, j, color)
    super(i, j, color)
    @ascii_code = color == 'white' ? "\u265E" : "\u2658"
    @type = "knight"
  end

  def get_poss_moves()
    moves = []
    moves.push([@pos_i + 2, @pos_j + 1])
    moves.push([@pos_i + 2, @pos_j - 1])
    moves.push([@pos_i - 2, @pos_j + 1])
    moves.push([@pos_i - 2, @pos_j - 1])
    moves.push([@pos_i + 1, @pos_j + 2])
    moves.push([@pos_i - 1, @pos_j + 2])
    moves.push([@pos_i + 1, @pos_j - 2])
    moves.push([@pos_i - 1, @pos_j - 2])
    moves.filter { |move| move.first >= 0 && move.last >= 0 && move.first <= 7 && move.last <= 7 }
  end

  def piece_valid_move?(i, j)
    valid_generic = super(i, j)
    i_dif = (@pos_i - i).abs
    j_dif = (@pos_j - j).abs
    valid_generic && ((i_dif == 1 && j_dif == 2) || (j_dif == 1 && i_dif == 2))
  end
end

class Bishop < Piece
  def initialize(i, j, color)
    super(i, j, color)
    @ascii_code = color == 'white' ? "\u265D" : "\u2657"
    @type = "bishop"
  end

  def get_poss_moves()
    moves = []
    # northeast:
    i, j = [@pos_i + 1, @pos_j + 1]
    until i > 7 || j > 7
      moves.push([i, j])
      i += 1
      j += 1
    end

    # northwest:
    i, j = [@pos_i - 1, @pos_j + 1]
    until i < 0 || j > 7
      moves.push([i, j])
      i -= 1
      j += 1
    end

    # southeast:
    i, j = [@pos_i + 1, @pos_j - 1]
    until i > 7 || j < 0
      moves.push([i, j])
      i += 1
      j -= 1
    end

    # southwest:
    i, j = [@pos_i - 1, @pos_j - 1]
    until i < 0 || j < 0
      moves.push([i, j])
      i -= 1
      j -= 1
    end

    moves
  end

  def piece_valid_move?(i, j)
    valid_generic = super(i, j)
    i_dif = (@pos_i - i).abs
    j_dif = (@pos_j - j).abs
    valid_generic && i_dif == j_dif
  end
end

class Queen < Piece
  def initialize(i, j, color)
    super(i, j, color)
    @ascii_code = color == 'white' ? "\u265B" : "\u2655"
    @type = "queen"
  end

  def get_poss_moves()
    bishop = Bishop.new(@pos_i, @pos_j, @color)
    rook = Rook.new(@pos_i, @pos_j, @color)

    bishop.get_poss_moves() + rook.get_poss_moves()
  end

  def piece_valid_move?(i, j)
    valid_generic = super(i, j)
    i_dif = (@pos_i - i).abs
    j_dif = (@pos_j - j).abs
    valid_generic && (i_dif == j_dif || ((i == @pos_i && j != @pos_j) || (j == @pos_j && i != @pos_i)))
  end
end

class King < Piece
  attr_accessor :moved
  def initialize(i, j, color)
    super(i, j, color)
    @ascii_code = color == 'white' ? "\u265A" : "\u2654"
    @type = "king"
    @moved = false
  end

  def get_poss_moves()
    moves = []
    moves.push([@pos_i - 1, @pos_j + 1])
    moves.push([@pos_i, @pos_j + 1])
    moves.push([@pos_i + 1, @pos_j + 1])
    moves.push([@pos_i - 1, @pos_j])
    moves.push([@pos_i + 1, @pos_j])
    moves.push([@pos_i - 1, @pos_j - 1])
    moves.push([@pos_i, @pos_j - 1])
    moves.push([@pos_i + 1, @pos_j - 1])
    moves.filter { |move| move.first >= 0 && move.last >= 0 && move.first <= 7 && move.last <= 7 }
  end
  
  def piece_valid_move?(i, j)
    # Doesn't take check into account, just returns true if move is valid for a king on an empty board
    valid_generic = super(i, j)
    i_dif = (@pos_i - i).abs
    j_dif = (@pos_j - j).abs
    return false if i_dif.zero? && j_dif.zero?

    valid_generic && ((i_dif.zero? || i_dif == 1) and (j_dif.zero? || j_dif == 1))
  end
end