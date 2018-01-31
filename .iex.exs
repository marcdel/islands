File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias IslandsEngine.{Board, Island, Coordinate, Guesses}