defmodule DMX.ArtnetFrame do
  require Logger

  def build_frame(data, seq_number, universe \\ 0) do
    protocol_version = "\x00\x0e"
    op_code = "\x00\x50"
    # # MAN_CODE = b"\x21\xa4"

    physical_port = "\x01"
    pck_length = "\x02\x00"

    # scaled_data = Enum.map(data, fn {k, v} -> {k, scaleX(v)} end) |> Map.new()

    "Art-Net\x00" <>
      op_code <>
      protocol_version <>
      <<seq_number::size(8)>> <>
      physical_port <>
      <<universe::little-size(16)>> <>
      pck_length <>
      build_frame_body(data)
  end


  @doc """
  From a data map build the binary frame body

    iex> DMX.ArtnetFrame.build_frame_body(%{1 => 56})
    <<56>> <> :binary.copy(<<0>>, 511)

    iex> DMX.ArtnetFrame.build_frame_body(%{2 => 56, 4=>78})
    <<0, 56, 0, 78>> <> :binary.copy(<<0>>, 508)

  """
  def build_frame_body(data) do
    Enum.map(1..512, fn x -> <<data[x] || 0>> end) |> Enum.reduce(&(&2 <> &1))
  end
end
