File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias IslandsEngine.{Game, GameSupervisor, Board, Island, Coordinate, Guesses, Rules}