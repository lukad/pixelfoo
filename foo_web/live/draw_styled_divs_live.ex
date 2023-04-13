defmodule FooWeb.DrawStyledDivsLive do
  use FooWeb, :live_view

  def mount(_params, _session, socket) do
    width = 10 * 8
    height = 8
    max_value = 7
    values = 0..max_value |> Enum.to_list()
    grid_height = 100 / (width / height)
    style = "grid-template-columns: repeat(#{width}, 1fr); height: #{grid_height}%;"

    if connected?(socket) do
      :timer.send_interval(100, self(), :tick)
    end

    pixels =
      List.duplicate(0, width * height)
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        %{id: index, value: value}
      end)

    internal_pixels = pixels

    pixel_styles =
      for n <-
            0..max_value do
        ".pixel-#{n} { background-color: hsl(0, 0%, #{100 - 100.0 / max_value * n}%); }"
      end
      |> Enum.join("\n")

    socket =
      socket
      |> assign(
        width: width,
        height: height,
        values: values,
        max_value: max_value,
        internal_pixels: internal_pixels,
        pixel_styles: pixel_styles,
        style: style,
        tick: 0,
        animate: false
      )

    socket = stream(socket, :pixels, pixels)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <style>
      <%= raw(@pixel_styles) %>
    </style>

    <div class="h-screen w-screen overflow-hidden flex items-center justify-center bg-red-500">
      <div class="landscape:w-full portrait:w-full aspect-[1/1] flex items-center overflow-hidden">
        <div class="grid gap-1 w-full" style={@style} id="pixels" phx-update="append">
          <div
            :for={{dom_id, pixel} <- @streams.pixels}
            id={dom_id}
            phx-value-id={pixel.id}
            class={["block", "pixel-#{pixel.value}"]}
            phx-click="toggle"
          >
          </div>
        </div>
      </div>
    </div>

    <div class="absolute bottom-0 right-0 text-white font-mono p-4 flex gap-2 text-2xl items-center">
      <div>Tick: <%= @tick %></div>
      <button class="bg-gray-800 px-4 py-2 rounded" phx-click="toggle_animation">
        Toggle Animation
      </button>
    </div>
    """
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    max_value = socket.assigns.max_value

    internal_pixels =
      socket.assigns.internal_pixels
      |> List.update_at(id, fn pixel ->
        %{pixel | value: rem(pixel.value + 1, max_value + 1)}
      end)

    updated_pixel = Enum.at(internal_pixels, id)

    socket =
      socket
      |> assign(internal_pixels: internal_pixels)
      |> stream_insert(:pixels, updated_pixel, at: updated_pixel.id)

    {:noreply, socket}
  end

  def handle_event("toggle_animation", %{}, socket) do
    socket = assign(socket, animate: !socket.assigns.animate)
    {:noreply, socket}
  end

  def handle_info(:tick, %{assigns: %{animate: true}} = socket) do
    socket = assign(socket, tick: socket.assigns.tick + 1)

    # animate pixel values sine wave
    max_value = socket.assigns.max_value
    width = socket.assigns.width
    tick = socket.assigns.tick

    socket =
      socket.assigns.internal_pixels
      |> Enum.map(fn pixel ->
        %{
          pixel
          | value:
              trunc(
                (:math.sin(tick + rem(pixel.id, width) + div(pixel.id, width) * tick / 10) + 1) /
                  2 *
                  max_value
              )
        }
      end)
      |> Enum.reduce(socket, fn pixel, socket ->
        stream_insert(socket, :pixels, pixel, at: pixel.id)
      end)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    {:noreply, socket}
  end
end
