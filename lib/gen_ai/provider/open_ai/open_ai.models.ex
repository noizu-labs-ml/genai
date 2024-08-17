defmodule GenAI.Provider.OpenAI.Models do

  def list() do
    []
  end

  def gpt_3_5_turbo() do
    %GenAI.Model{
      model: "gpt-3.5-turbo",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_3_5_turbo_16k() do
    %GenAI.Model{
      model: "gpt-3.5-turbo",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4() do
    %GenAI.Model{
      model: "gpt-4",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4_turbo() do
    %GenAI.Model{
      model: "gpt-4-turbo",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4_turbo_preview() do
    %GenAI.Model{
      model: "gpt-4-turbo-preview",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4_vision() do
    %GenAI.Model{
      model: "gpt-4",
      provider: GenAI.Provider.OpenAI
    }
  end


  def gpt_4o() do
    %GenAI.Model{
      model: "gpt-4o",
      provider: GenAI.Provider.OpenAI
    }
  end

  def gpt_4o_mini() do
    %GenAI.Model{
      model: "gpt-4o-mini",
      provider: GenAI.Provider.OpenAI
    }
  end


end
