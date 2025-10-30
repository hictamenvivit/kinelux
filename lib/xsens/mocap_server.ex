defmodule Xsens.MocapServer do
  require Logger
  use GenServer

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, port, name: name)
  end

  @impl true
  def init(port) do
    Logger.warning(port)

    case :gen_udp.open(port, [:binary, active: true]) do
      {:ok, socket} ->
        IO.puts("UDP Server listening on port #{port}")
        {:ok, %{socket: socket}}

      {:error, reason} ->
        IO.puts("Error opening UDP socket: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_info({:udp, _socket, _ip, _port, data}, state) do
    # IO.puts()
    case Xsens.MocapData.parse(data) do
      {:ok, {type, message_content}} ->
        handle_type(type, message_content)

      {:error, reason} ->
        IO.puts("Failed to parse UDP packet: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  defp handle_type(:type01, content) do
    <<
      _header_1::binary-size(6),
      tc::unsigned-integer-size(32),
      _header_2::binary-size(8),
      rest::binary
    >> = content

    {:ok, parsed_first_segment} = Xsens.MocapData.parse_message_body(rest)
    parsed_first_segment_with_tc = Map.put(parsed_first_segment, :tc, tc)

    Bucket.update(:bucket, parsed_first_segment_with_tc )

    # send(:bucket, )
    # send(:websocket_server, parsed_first_segment)
  end

  defp handle_type(:type12, _content) do
    IO.puts("Received type 12")
  end

  defp handle_type(:type13, _content) do
    IO.puts("Received type 13")
  end
end
