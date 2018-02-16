File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias IslandsEngine.{GameSupervisor, GameState, Game, Board, Island, Coordinate, Guesses, Rules}