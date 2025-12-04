defmodule Bucket do
  use GenServer

  @doc """
  Starts a new bucket.
  """
  def start_link({name}) do
    GenServer.start_link(
      __MODULE__,
      %{},
      name: name
    )
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket) do
    GenServer.call(bucket, :get)
  end

  # TODO: obviously should have a second parameter
  def get_mode(bucket) do
    GenServer.call(bucket, :get_mode)
  end

  def change_mode(bucket, mode) do
    modes = [
      :reset,
      :ic_matrix,
      :rotate_cct
    ]

    if mode in modes do
      GenServer.call(bucket, {:change_mode, mode})
      :ok
    else
      :unknown_mode
    end
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def update(bucket, new_position) do
    GenServer.call(bucket, {:update, new_position})
  end

  ### Callbacks

  @impl true
  @spec init(any()) :: {:ok, %{position_data: any()}}
  def init(_args) do
    initial_segment = %{
      x: 0.0,
      y: 0.0,
      z: 0.0,
      rx: 0.0,
      ry: 0.0,
      rz: 0.0
    }

    state = %{
      position_data: %{
        segments: for(_ <- 1..23, do: initial_segment),
        speed: 0.0,
        tc: 0.0,
        highest_point: 0.0,
        spread: 0.0
      },
      mode: :reset
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state.position_data, state}
  end

  @impl true
  def handle_call(:get_mode, _from, state) do
    {:reply, state.mode, state}
  end

  def handle_call({:update, new_position}, _from, state) do
    old_position = state.position_data

    first_segment = new_position.segments |> hd
    old_first_segment = old_position.segments |> hd

    speed =
      :math.sqrt(
        :math.pow(first_segment.x - old_first_segment.x, 2) +
          :math.pow(first_segment.y - old_first_segment.y, 2)
      )

    x_values = Enum.map(new_position.segments, &Map.get(&1, :x))
    y_values = Enum.map(new_position.segments, &Map.get(&1, :y))
    z_values = Enum.map(new_position.segments, &Map.get(&1, :z))

    highest_point =
      Enum.max(y_values)

    # IO.puts(highest_point)

    spread =
      (Enum.max(x_values) - Enum.min(x_values)) *
        (Enum.max(y_values) - Enum.min(y_values)) *
        (Enum.max(z_values) - Enum.min(z_values))

    position_data = %{
      segments: new_position.segments,
      highest_point: highest_point,
      tc: new_position.tc,
      speed: speed,
      spread: spread
    }

    state = put_in(state.position_data, position_data)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:change_mode, new_mode}, _from, state) do
    state = put_in(state.mode, new_mode)
    {:reply, :ok, state}
  end
end
