defmodule DMX.ArtnetServer do
  use GenServer
  require Logger

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, port, name: name)
    Task.start_link(&loop_send_frame/0)
  end

  @impl true
  @spec init(any()) :: {:ok, %{socket: port() | {:"$inet", atom(), any()}}}
  def init(_port) do
    {:ok, socket} = :gen_udp.open(0, [:binary])
    {:ok, %{socket: socket}}
  end

  @impl true
  def handle_info({:udp, _socket, _address, _port, _data}, state) do
    Logger.info("Received UDP data")

    {:noreply, state}
  end

  defp loop_send_frame(seq \\ 0) do
    :timer.sleep(trunc(1000 / 40))
    GenServer.cast(self(), {:send_frame, seq})
    IO.puts("AAAAA")

    new_seq = rem(seq, 255) + 1
    loop_send_frame(new_seq)
    # {:ok}
  end

  @impl true
  def handle_cast({:send_frame, seq}, %{socket: socket} = state) do
    IO.puts("😃")
    position = Bucket.get(:bucket)
    dmx_value = scale(position.speed * 100, 0, 15)

    mapping = %{
      201 => dmx_value
      # 202 => scale(speedX * 100, 0, 125)
    }

    frame = DMX.ArtnetFrame.build_frame(mapping, seq)
    # TODO: retrieve port properly
    # TODO: retrieve address properly
    # IO.puts("sending frame #{message}")
    :gen_udp.send(socket, {2, 0, 0, 1}, 6454, frame)
    IO.puts("Sent frame")
    {:noreply, state}
  end

  defp scale(value, minimum \\ 0, maximum \\ 100) do
    spread = maximum - minimum
    calculated = trunc((value - minimum) * (255 / spread))
    trunc(max(0, min(512, calculated)))
  end
end
