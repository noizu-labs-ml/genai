defmodule GenAI.Model.MetaDataManagerTest do
  use ExUnit.Case
  @moduletag :wip2
  doctest GenAI.MetaDataLoader.Helper

  test "Load Meta Data From Disk" do
    sut = GenAI.MetaDataLoader.load()
    assert sut == :wip
  end


end
