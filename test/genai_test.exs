defmodule GenaiTest do
  use ExUnit.Case
  doctest Genai

  test "greets the world" do
    assert Genai.hello() == :world
  end
end
