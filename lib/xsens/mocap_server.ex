defmodule Xsens.MocapServer do
  require Logger
  use GenServer

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, port, name: name)
  end

  @impl true
  def init(port) do
    Logger.warning(port)

    mode = :test

    ip =
      case mode do
        :prod -> {192, 168, 1, 32}
        :test -> {127, 0, 0, 1}
      end

    # TODO: obviously not here
    case :gen_udp.open(port, [:binary, active: true, ip: ip]) do
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
    case Xsens.MocapData.parse(data) do
      {:ok, {type, message_content}} ->
        handle_type(type, message_content)

      {:error, reason} ->
        nil
        # IO.puts("Failed to parse UDP packet: #{inspect(reason)}")
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

    {:ok, parsed_segments} = Xsens.MocapData.parse_message_body(rest)
    parsed_segments_with_tc = Map.put(parsed_segments, :tc, tc)

    Bucket.update(:bucket, parsed_segments_with_tc)

    # send(:bucket, )
    # send(:websocket_server, parsed_first_segment)
  end

  defp handle_type(:type12, _content) do
    # IO.puts("Received type 12")
  end

  defp handle_type(:type13, _content) do
    # IO.puts("Received type 13")
  end
end
