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
    state = %{
      position_data: %{
        x: 0.0,
        y: 0.0,
        z: 0.0,
        rx: 0.0,
        ry: 0.0,
        rz: 0.0,
        speed: 0.0,
        tc: 0.0
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state.position_data, state}
  end

  def handle_call({:update, new_position}, _from, state) do
    old_position = state.position_data

    speed =
      :math.sqrt(
        :math.pow(new_position.x - old_position.x, 2) +
          :math.pow(new_position.y - old_position.y, 2)
      )

    position_data = %{
      x: new_position.x,
      y: new_position.y,
      z: new_position.z,
      rx: new_position.rx,
      ry: new_position.ry,
      rz: new_position.rz,
      tc: new_position.tc,
      speed: speed
    }

    state = put_in(state.position_data, position_data)
    {:reply, :ok, state}
  end
end
