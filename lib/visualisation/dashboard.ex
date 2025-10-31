defmodule Visualisation.Dashboard do
  use GenServer
  require Logger

  def start_link({name}) do
    GenServer.start_link(__MODULE__, name: name)
  end

  @impl true
  @spec init(any()) :: {:ok}
  def init(_port) do
    Process.send(self(), :update, [])
    {:ok, %{}}
  end

  @impl true
  def handle_info(:update, state) do
    Process.send_after(self(), :update, 200)
    position = Bucket.get(:bucket)
    # clear screen (ANSI escape)
    # IO.write("\e[H\e[2J")
    # IO.puts("\n\n\n=== Dashboard ===")

    # Enum.each(position, fn {k, v} ->
    #   case v do
    #     x when is_integer(x) -> IO.puts("#{k}: #{x}")
    #     x when is_float(x) -> IO.puts("#{k}: #{Float.round(x, 2)}")
    #   end
    # end)

    {:noreply, state}
  end
end
