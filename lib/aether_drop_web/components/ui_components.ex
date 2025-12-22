defmodule AetherDropWeb.UIComponents do
  use Phoenix.Component

  attr :class, :string, default: nil
  attr :style, :string, default: nil
  slot :inner_block, required: true

  def glass_card(assigns) do
    ~H"""
    <div class={["glass-card", @class]} style={@style}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def glass_panel(assigns) do
    ~H"""
    <div class={["glass-panel", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :style, :string, default: nil
  slot :inner_block, required: true

  def bento_card(assigns) do
    ~H"""
    <div
      class={[
        "bento-card glass-card rounded-3xl p-8 relative overflow-hidden group hover:bg-slate-800/50 transition-colors",
        @class
      ]}
      style={@style}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :text, :string, default: nil
  slot :inner_block

  def text_gradient(assigns) do
    ~H"""
    <span class="text-gradient">
      {if @text, do: @text, else: render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :href, :string, default: "#"
  slot :inner_block, required: true

  def primary_button(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        "group relative px-8 py-4 bg-gradient-to-r from-cyan-500 to-blue-600 rounded-xl font-bold text-white shadow-[0_0_30px_rgba(56,189,248,0.3)] hover:shadow-[0_0_50px_rgba(56,189,248,0.5)] transition-all hover:-translate-y-1 overflow-hidden text-center",
        @class
      ]}
    >
      <div class="absolute inset-0 bg-white/20 group-hover:translate-x-full transition-transform duration-700 -skew-x-12 -translate-x-full">
      </div>
      <span class="relative flex items-center justify-center gap-2">
        {render_slot(@inner_block)}
      </span>
    </a>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :string, default: nil
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={@on_cancel}
      class={["relative z-50", if(@show, do: "block", else: "hidden")]}
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm transition-opacity"
        aria-hidden="true"
      />
      <div class="fixed inset-0 flex items-center justify-center p-4">
        <div class="relative transform overflow-hidden rounded-2xl bg-white dark:bg-slate-900 text-left shadow-xl transition-all sm:w-full sm:max-w-lg border border-slate-200 dark:border-slate-700">
          <button
            phx-click={@on_cancel}
            class="absolute right-4 top-4 text-slate-400 hover:text-slate-500"
          >
            <i class="ph-bold ph-x text-xl"></i>
          </button>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %Phoenix.LiveView.JS{}, id) do
    js
    |> Phoenix.LiveView.JS.show(to: "##{id}")
    |> Phoenix.LiveView.JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> Phoenix.LiveView.JS.show(
      to: "##{id}-container",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide_modal(js \\ %Phoenix.LiveView.JS{}, id) do
    js
    |> Phoenix.LiveView.JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> Phoenix.LiveView.JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
  end
end
