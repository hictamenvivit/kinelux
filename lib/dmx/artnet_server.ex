defmodule DMX.ArtnetServer do
  use GenServer
  require Logger

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, port, name: name)
  end

  @impl true
  def init(_port) do
    initial_position = %{x: 0, y: 0, z: 0, rx: 0, ry: 0, rz: 0, tc: 0}

    {:ok, socket} = :gen_udp.open(0, [:binary])
    {:ok, %{socket: socket, seq: 0, position: initial_position}}
  end

  @impl true
  def handle_info({:udp, _socket, address, port, data}, state) do
    Logger.info("Received UDP data")

    {:noreply, state}
  end

  @impl true
  def handle_info(position, %{socket: socket, seq: prev_seq, position: prev_position}) do
    # Logger.info("Data is now #{inspect(position)}")

    seq = rem(prev_seq, 255) + 1

    # units in cm.millis-1 -> *10 for m.s-1
    speedX = abs((position.x - prev_position.x) / (position.tc - prev_position.tc)) * 10

    speed =
      :math.sqrt(
        :math.pow(position.x - prev_position.x, 2) + :math.pow(position.z - prev_position.z, 2)
      ) / (position.tc - prev_position.tc)

    IO.puts("🦆")
    IO.puts(trunc(speed * 100))
    # IO.puts(position.x)
    # IO.puts(position.tc)
    # IO.puts(prev_position.x)
    # IO.puts(prev_position.tc)

    dmx_value = scale(speed * 100, 0, 15)
    IO.puts(dmx_value)

    mapping = %{
      201 => dmx_value
      # 202 => scale(speedX * 100, 0, 125)
    }

    frame = DMX.ArtnetFrame.build_frame(mapping, seq)
    GenServer.cast(self(), {:send, frame})

    {:noreply, %{socket: socket, seq: seq, position: position}}
  end

  @impl true
  def handle_cast({:send, message}, %{socket: socket} = state) do
    # TODO: retrieve port properly
    # TODO: retrieve address properly
    # IO.puts("sending frame #{message}")
    :gen_udp.send(socket, {2, 0, 0, 1}, 6454, message)
    {:noreply, state}
  end

  defp scale(value, minimum \\ 0, maximum \\ 100) do
    spread = maximum - minimum
    calculated = trunc((value - minimum) * (255 / spread))
    trunc(max(0, min(512, calculated)))
  end
end
