defmodule Xsens.MocapData do
  def parse(<<"MXTP", type::binary-size(2), rest::binary>>) do
    case type do
      "01" -> {:ok, {:type01, rest}}
      "12" -> {:ok, {:type12, rest}}
      "13" -> {:ok, {:type13, rest}}
      _ -> {:error, "Unknown message type #{type}"}
    end
  end

  def parse(<<header::binary-size(4), _::binary>>) do
    {:error, "Unknown header #{header}"}
  end

  def parse(_), do: {:error, "Invalid frame"}

  def parse_message_body(<<data::binary-size(644)>>) do
    <<first_segment::binary-size(28), _rest::binary>> = data
    parse_segment(first_segment)
  end

  defp parse_segment(<<
         id::32-little,
         x::float-32,
         y::float-32,
         z::float-32,
         rx::float-32,
         ry::float-32,
         rz::float-32
       >>) do
    {:ok,
     %{
       id: id,
       x: x,
       y: y,
       z: z,
       rx: rx,
       ry: ry,
       rz: rz
     }}
  end
end
