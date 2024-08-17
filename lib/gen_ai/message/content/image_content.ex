defmodule GenAI.Message.Content.ImageContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct [
    type: nil,
    resolution: nil,
    resource: nil,
    options: nil,
    vsn: @vsn
  ]

  def image_type(resource) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".png") ->:png
      String.ends_with?(resource, ".jpg") -> :jpeg
      String.ends_with?(resource, ".jpeg") -> :jpeg
      String.ends_with?(resource, ".gif") -> :gif
      String.ends_with?(resource, ".bmp") -> :bmp
      String.ends_with?(resource, ".tiff") -> :tiff
      String.ends_with?(resource, ".webp") -> :webp
      true -> throw "Unsupported image type: #{resource}"
    end
  end

  def resolution(_), do: :auto

  def base64(image, options \\ nil)
  def base64(image, _) do
    binary = File.read!(image.resource)
    {:ok, Base.encode64(binary)}
  end

  @doc """
  Prepare new image message content item.
  """
  def new(resource, options \\ nil)
  def new(resource, options) when is_bitstring(resource) do
    File.exists?(resource) || throw "Resource not found: #{resource}"
    %__MODULE__{
      type: image_type(resource),
      resolution: resolution(resource),
      resource: resource,
      options: options
    }
  end


  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end

end
