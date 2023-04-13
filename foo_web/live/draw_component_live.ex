defmodule FooWeb.DrawComponentLive do
  use FooWeb, :live_view

  def mount(_params, _session, socket) do
    width = 64
    height = 16
    max_value = 7
    style = "grid-template-columns: repeat(#{width}, minmax(0, 1fr));"

    pixels =
      List.duplicate(0, width * height)
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        %{id: index, value: value}
      end)

    socket =
      socket
      |> assign(
        width: width,
        height: height,
        max_value: max_value,
        pixels: pixels,
        style: style
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="grid gap-2" style={@style}>
      <div :for={pixel <- @pixels} class="select-none">
        <.live_component module={FooWeb.Pixel} id={pixel.id} value={pixel.value} />
      </div>
    </div>
    """
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    max_value = socket.assigns.max_value

    pixels =
      socket.assigns.pixels
      |> List.update_at(id, fn pixel ->
        %{pixel | value: rem(pixel.value + 1, max_value + 1)}
      end)

    socket = assign(socket, :pixels, pixels)

    {:noreply, socket}
  end
end
