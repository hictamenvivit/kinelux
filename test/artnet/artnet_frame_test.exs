defmodule DMX.ArtnetFrameTest do
  use ExUnit.Case

  doctest DMX.ArtnetFrame

  test "builds an Art-Net frame" do
    # OpCodeLittle endian
    # ProtoHi
    # ProtoLo
    # Seq
    # Physical
    # Universe LE
    # Length Hi
    # Length Lo
    # Channel 1
    # rest of the channel
    target =
      "Art-Net\0" <>
        "\x00\x50" <>
        "\0" <>
        "\x0E" <>
        "\x01" <>
        "\x01" <>
        "\x03\0" <>
        "\x02" <>
        "\x00" <>
        "\x8A" <>
        :binary.copy(<<0>>, 511)

    assert DMX.ArtnetFrame.build_frame(%{1 => 34}, 1, 3) == target
  end

  test "builds the Artnet frame body" do
    assert DMX.ArtnetFrame.build_frame_body(%{1 => 34}) == "\x22" <> :binary.copy(<<0>>, 511)
  end
end
