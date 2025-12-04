defmodule DMX.ArtnetServer do
  use GenServer
  require Logger

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, port, name: name)
  end

  @impl true
  @spec init(any()) :: {:ok, %{socket: port() | {:"$inet", atom(), any()}}}
  def init(_port) do
    mode = :test

    ip =
      case mode do
        :test -> {127, 0, 0, 1}
        :prod -> {2, 0, 0, 2}
      end

    {:ok, socket} = :gen_udp.open(0, [:binary, ip: ip])
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
    # TODO: make less ugly
    mode = Bucket.get_mode(:bucket)
    first_segment = position.segments |> hd
    dmx_speed = scale(position.speed * 100, 0, 60)
    dmx_x = scale(first_segment.x, -400, 400)
    dmx_z = scale(first_segment.z, -400, 400)

    dmx_ry = scale(first_segment.ry, -90, 90)

    # IO.puts("Speed * 100 =  #{position.speed * 100}, dmx = #{dmx_speed} ")
    # IO.puts(seq)
    # IO.puts(position.highest_point)
    # IO.puts(position.spread)

    dmx_highest_point = scale(position.highest_point, 20, 150)
    # IO.puts(dmx_speed)

    first_lamp = 257
    second_lamp = 272
    third_lamp = 1

    intensities_addresses = [first_lamp, second_lamp, third_lamp]
    ccts_addresses = Enum.map(intensities_addresses, fn x -> x + 1 end)

    # mode = :reset

    mapping =
      build_mapping(
        case mode do
          :rotate_cct ->
            [
              {255, intensities_addresses},
              {dmx_ry, ccts_addresses}
            ]

          :ic_matrix ->
            [
              {dmx_x, intensities_addresses},
              {dmx_z, ccts_addresses}
            ]

          :reset ->
            []

          _ ->
            IO.puts("Unknown mode" <> inspect(mode))
            []
        end
      )

    # mapping |> inspect() |> IO.puts()

    frame = DMX.ArtnetFrame.build_frame(mapping, seq, 0)
    # write_to_file("DATA", frame)
    # TODO: retrieve port properly
    # TODO: retrieve address properly
    # IO.puts("sending frame #{message}")
    :gen_udp.send(socket, {2, 0, 0, 1}, 6454, frame)
    # IO.puts(frame)

    {:noreply, %{socket: socket, seq: rem(seq + 1, 255)}}
  end

  defp scale(value, minimum \\ 0, maximum \\ 100) do
    spread = maximum - minimum
    calculated = trunc((value - minimum) * (255 / spread))
    trunc(max(0, min(255, calculated)))
  end

  def build_mapping(reverse_mapping) do
    Enum.reduce(
      reverse_mapping,
      %{},
      fn {value, keys}, acc ->
        Enum.reduce(keys, acc, fn key, akk -> Map.put(akk, key, value) end)
      end
    )
  end
end
