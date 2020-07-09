# CHESS IN RUBY
This repository is an implementation of chess I made in Ruby for The Odin Project.


## About
This is played via the command line interface by running the file 'main.rb' in the lib directory. It is a two-player, pass-and-play game.

Moves must be in proper algebraic notation. Some notes on the implementation:
- Castling must be indicated with zeroes- i.e. '0-0' for king-side castles and '0-0-0' for queen-side.
- Check and check mate indicators should not be added to the move string. Check and check mate are calculated automatically after each move, and a message is displayed when appropriate.
- En passant captures should be entered as a normal pawn move. The captured piece will be removed automatically.

## Outstanding Features
- Pawn promotion
- Game saving
- AI opponent
