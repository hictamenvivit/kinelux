defmodule Kinelux do
  @moduledoc """
  Documentation for `Kinelux`.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Xsens.MocapServer, {5005, :mocap_server}},
      {DMX.ArtnetServer, {6454, :artnet_server}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
