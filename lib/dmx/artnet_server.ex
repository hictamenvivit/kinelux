defmodule DMX.ArtnetServer do
  use GenServer
  require Logger

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, port, name: name)
  end

  @impl true
  @spec init(any()) :: {:ok, %{socket: port() | {:"$inet", atom(), any()}}}
  def init(_port) do
    {:ok, socket} = :gen_udp.open(0, [:binary])
    Process.send(self(), :send_frame, [])
    {:ok, %{socket: socket, seq: 0}}
  end

  @impl true
  def handle_info({:udp, _socket, _address, _port, _data}, state) do
    Logger.info("Received UDP data")

    {:noreply, state}
  end

  defp write_to_file(filename, data) do
    File.open(filename, [:append])
    |> elem(1)
    |> IO.binwrite(data)
  end

  @impl true
  def handle_info(:send_frame, %{socket: socket, seq: seq} = state) do
    Process.send_after(self(), :send_frame, trunc(1000 / 40))
    position = Bucket.get(:bucket)
    dmx_value_speed = scale(position.speed * 100, 0, 60)
    dmx_value_x = scale(position.x, -400, 400)

    # IO.puts("Speed * 100 =  #{position.speed * 100}, dmx_value = #{dmx_value_speed} ")
    IO.puts(seq)

    mapping = %{
      2 => dmx_value_speed,
      9 => dmx_value_speed,
      16 => dmx_value_speed,
      202 => 0
      # 202 => scale(speedX * 100, 0, 125)
    }

    frame = DMX.ArtnetFrame.build_frame(mapping, seq, 1)
    # write_to_file("DATA", frame)
    # TODO: retrieve port properly
    # TODO: retrieve address properly
    # IO.puts("sending frame #{message}")
    :gen_udp.send(socket, {127, 0, 0, 1}, 6454, frame)
    # IO.puts(frame)

    {:noreply, %{socket: socket, seq: rem(seq + 1, 255)}}
  end

  defp scale(value, minimum \\ 0, maximum \\ 100) do
    spread = maximum - minimum
    calculated = trunc((value - minimum) * (255 / spread))
    trunc(max(0, min(255, calculated)))
  end
end
