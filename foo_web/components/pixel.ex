defmodule FooWeb.Pixel do
  use FooWeb, :live_component

  attr :value, :integer, default: 0
  attr :id, :integer, default: 0

  def render(assigns) do
    ~H"""
    <div phx-value-id={@id} phx-click="toggle">
      <%= @value %>
    </div>
    """
  end
end
