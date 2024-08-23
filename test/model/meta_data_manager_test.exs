defmodule GenAI.Model.MetaDataManagerTest do
  use ExUnit.Case

  @tag :wip2
  test "Load Meta Data From Disk" do
    sut = GenAI.Model.MetaDataManager.load()
    IO.inspect(sut, label: "SUT")
  end


end
