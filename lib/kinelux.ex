defmodule Kinelux do
  @moduledoc """
  Documentation for `Kinelux`.
  """
  use Application

  def mode(mode) do
    case Bucket.change_mode(:bucket, mode) do
      :ok -> IO.puts("Changed to mode" <> inspect(mode))
      :unknown_mode -> IO.puts("Unknown mode" <> inspect(mode))
    end
  end

  @impl true
  def start(_type, _args) do
    children = [
      {Xsens.MocapServer, {9764, :mocap_server}},
      {DMX.ArtnetServer, {6454, :artnet_server}},
      {Bucket, {:bucket}},
      {Visualisation.Dashboard, {:dashboard}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
