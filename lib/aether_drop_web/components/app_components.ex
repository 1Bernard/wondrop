defmodule AetherDropWeb.AppComponents do
  use Phoenix.Component

  @doc """
  Renders the interactive Radar component.
  """
  attr :mode, :atom, default: :local, values: [:local, :bridge]
  attr :devices, :list, default: []
  attr :selected_peer_id, :string, default: nil
  attr :connecting_peer_id, :string, default: nil
  attr :connected_peer_ids, :any, default: MapSet.new()
  attr :scanning, :boolean, default: false

  def radar(assigns) do
    ~H"""
    <div class="p-4 border-b border-slate-200 dark:border-slate-700/50 flex justify-between items-center z-10 bg-white/50 dark:bg-slate-900/50 backdrop-blur-sm">
      <h3 class="font-bold text-sm uppercase tracking-wider text-slate-500 flex items-center gap-2">
        <i class="ph-bold ph-radar"></i> Nearby
      </h3>
      <button
        phx-click="scan"
        disabled={@scanning}
        class={[
          "text-xs font-bold uppercase tracking-wide transition-colors flex items-center gap-1 group",
          if(@scanning,
            do: "text-sky-500 cursor-wait",
            else: "text-sky-600 dark:text-sky-500 hover:text-sky-500 dark:hover:text-sky-400"
          )
        ]}
      >
        <i class={["ph-bold ph-arrows-clockwise", if(@scanning, do: "animate-spin")]}></i>
        {if @scanning, do: "Scanning...", else: "Scan"}
      </button>
    </div>

    <div
      id="radar-view"
      class={[
        "flex-1 relative flex items-center justify-center transition-colors duration-500",
        if(@mode == :bridge,
          do: "radar-mode-bridge bg-purple-100/50 dark:bg-purple-900/10",
          else: "radar-mode-local bg-slate-50/50 dark:bg-slate-900/30"
        )
      ]}
    >
      <!-- Radar Animation Circles -->
      <div class="radar-circle"></div>
      <div class="radar-circle"></div>
      <div class="radar-circle"></div>
      
    <!-- Center Dot -->
      <div class={[
        "w-4 h-4 rounded-full shadow-lg z-10 relative transition-all duration-500",
        if(@mode == :bridge,
          do: "bg-purple-500 shadow-purple-500/50",
          else: "bg-sky-500 shadow-sky-500/50"
        )
      ]}>
        <div class={[
          "absolute -inset-4 rounded-full animate-ping transition-colors duration-500",
          if(@mode == :bridge, do: "bg-purple-500/20", else: "bg-sky-500/20")
        ]}>
        </div>
      </div>
      
    <!-- Discovered Devices -->
      <%= for device <- @devices do %>
        <.device_node
          device={device}
          selected={@selected_peer_id == device.id}
          connecting={@connecting_peer_id == device.id}
          connected={MapSet.member?(@connected_peer_ids, device.id)}
        />
      <% end %>
    </div>
    """
  end

  attr :device, :map, required: true
  attr :selected, :boolean, default: false
  attr :connecting, :boolean, default: false
  attr :connected, :boolean, default: false

  def device_node(assigns) do
    ~H"""
    <button
      phx-click="select_device"
      phx-value-id={@device.id}
      class="absolute group transition-all duration-500 transform hover:scale-110 focus:outline-none z-30"
      style={"top: #{@device.y}%; left: #{@device.x}%"}
      title={@device.name}
    >
      <div class={[
        "w-14 h-14 rounded-2xl bg-slate-100 dark:bg-slate-800 border-2 flex items-center justify-center shadow-xl relative transition-all duration-300",
        if(@selected,
          do: "border-green-500 dark:border-green-500 ring-4 ring-green-500/30 scale-110",
          else:
            if(@connecting,
              do: "border-sky-500 ring-4 ring-sky-500/30 animate-pulse",
              else:
                "border-slate-200 dark:border-slate-700 group-hover:border-sky-400 dark:group-hover:border-sky-500"
            )
        )
      ]}>
        <i class={[
          "ph-duotone text-2xl transition-colors",
          if(@device.type == :mobile, do: "ph-device-mobile", else: "ph-desktop"),
          cond do
            @selected -> "text-green-600 dark:text-green-500"
            @connected -> "text-sky-600 dark:text-sky-400"
            true -> "text-slate-700 dark:text-slate-200"
          end
        ]}>
        </i>
        <div
          :if={@selected or @connected}
          class={[
            "absolute -top-1 -right-1 w-4 h-4 border-2 border-white dark:border-slate-800 rounded-full",
            if(@selected,
              do: "bg-green-500",
              else: "bg-sky-500 shadow-[0_0_8px_rgba(14,165,233,0.8)]"
            )
          ]}
        >
          <div
            :if={@connected}
            class="absolute inset-0 bg-sky-400 rounded-full animate-ping opacity-75"
          >
          </div>
        </div>
      </div>
      <span class={[
        "absolute -bottom-7 left-1/2 -translate-x-1/2 text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded transition-all whitespace-nowrap bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-300 shadow-sm z-40",
        if(@selected or @connected,
          do: "opacity-100",
          else: "opacity-0 group-hover:opacity-100"
        )
      ]}>
        {@device.name}
        <span :if={@connected} class="ml-1 text-[8px] text-sky-500">LIVE</span>
      </span>
      <div
        :if={@connecting}
        class="absolute -bottom-10 left-1/2 -translate-x-1/2 flex items-center gap-1 bg-sky-500 text-white text-[9px] font-bold uppercase tracking-widest px-1.5 py-0.5 rounded shadow-lg animate-bounce"
      >
        <i class="ph-bold ph-circle-notch animate-spin"></i> Connecting
      </div>
    </button>
    """
  end

  attr :active_tab, :string, required: true
  attr :chat_unread_count, :integer, default: 0
  attr :files_unread_count, :integer, default: 0

  def tab_navigation(assigns) do
    ~H"""
    <div
      id="tab-navigation"
      phx-hook="Tabs"
      class="flex p-1 bg-slate-200/80 dark:bg-slate-800/80 backdrop-blur rounded-xl w-full md:w-fit overflow-x-auto"
    >
      <.tab_button
        name="files"
        icon="ph-files"
        label="Files"
        active={@active_tab == "files"}
        badge={@files_unread_count}
      />
      <.tab_button
        name="clipboard"
        icon="ph-clipboard-text"
        label="Clipboard"
        active={@active_tab == "clipboard"}
      />
      <.tab_button
        name="chat"
        icon="ph-chat-circle-dots"
        label="Chat"
        active={@active_tab == "chat"}
        badge={@chat_unread_count}
      />
    </div>
    """
  end

  attr :name, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :badge, :integer, default: 0

  def tab_button(assigns) do
    ~H"""
    <button
      type="button"
      data-tab-target={@name}
      class={[
        "flex-1 md:flex-none px-6 py-2 rounded-lg text-sm transition-all flex items-center justify-center gap-2 whitespace-nowrap",
        if(@active,
          do: "bg-white dark:bg-slate-700 text-sky-600 dark:text-sky-400 shadow-sm font-bold",
          else: "font-medium text-slate-500 hover:text-slate-800 dark:hover:text-slate-200"
        )
      ]}
    >
      <i class={["ph-bold", @icon]}></i> {@label}
      <%= if @badge > 0 do %>
        <span class="ml-1 bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-sm animate-pulse">
          {@badge}
        </span>
      <% end %>
    </button>
    """
  end

  attr :transfers, :list, default: []
  attr :device_id, :string, required: true

  def file_list(assigns) do
    ~H"""
    <div class="flex-1 overflow-y-auto space-y-3 pr-2 scroll-smooth">
      <%= if @transfers == [] do %>
        <div class="h-full flex flex-col items-center justify-center text-slate-400 opacity-60 pb-10">
          <i class="ph-duotone ph-files text-6xl mb-2"></i>
          <p class="text-sm">No transfers yet</p>
        </div>
      <% else %>
        <div
          :for={transfer <- @transfers}
          class="glass-panel p-3 rounded-xl flex items-center gap-3 relative overflow-hidden animate-slide-in group hover:bg-white/60 dark:hover:bg-slate-800/60 transition-colors border border-transparent hover:border-slate-200 dark:hover:border-slate-700"
        >
          <!-- File Icon based on extension -->
          <div class="w-10 h-10 rounded-lg bg-indigo-50 dark:bg-slate-700 flex items-center justify-center text-indigo-500 dark:text-indigo-400 shrink-0">
            <%= if transfer.sender_id == @device_id do %>
              <i class="ph-fill ph-paper-plane-tilt text-xl"></i>
            <% else %>
              <i class="ph-fill ph-file-text text-xl"></i>
            <% end %>
          </div>
          
    <!-- File Info -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between mb-0.5">
              <h5 class="font-bold text-sm truncate text-slate-700 dark:text-slate-200">
                {transfer.filename}
              </h5>
              <span class="text-[10px] font-mono text-slate-400">
                {Decimal.div(transfer.size, 1024) |> Decimal.round(1)} KB
              </span>
            </div>
            <div class="flex items-center gap-2">
              <div class="h-1.5 flex-1 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                <div
                  class={[
                    "h-full rounded-full transition-all duration-300",
                    if(transfer.state == :pending, do: "w-0 animate-pulse bg-slate-400/50"),
                    if(transfer.state == :sending, do: "bg-sky-500"),
                    if(transfer.state == :completed, do: "w-full bg-green-500")
                  ]}
                  style={if transfer.state == :sending, do: "width: #{transfer.progress}%", else: ""}
                >
                </div>
              </div>
              <span class={[
                "text-[10px] uppercase font-bold tracking-wider",
                if(transfer.state == :completed, do: "text-green-500", else: "text-slate-400")
              ]}>
                {if transfer.state == :sending, do: "#{transfer.progress}%", else: transfer.state}
              </span>
            </div>
          </div>
          <!-- Actions -->
          <div class="flex items-center gap-1">
            <!-- Accept/Decline (For Receiver in Pending state) -->
            <%= if transfer.state == :pending and transfer.sender_id != @device_id do %>
              <button
                phx-click="file:accept"
                phx-value-id={transfer.id}
                class="px-3 py-1.5 bg-sky-500 hover:bg-sky-400 text-white text-[10px] font-bold rounded-lg transition-colors flex items-center gap-1.5"
                title="Accept Transfer"
              >
                <i class="ph-bold ph-check"></i> Accept
              </button>
              <button
                phx-click="remove_transfer"
                phx-value-id={transfer.id}
                class="w-8 h-8 rounded-full hover:bg-slate-200 dark:hover:bg-slate-700 flex items-center justify-center text-slate-400 hover:text-red-500 transition-colors"
                title="Decline"
              >
                <i class="ph-bold ph-x"></i>
              </button>
            <% else %>
              <!-- Only show download if completed AND NOT Sender -->
              <%= if (transfer.state == :completed or transfer.progress >= 100) and transfer.sender_id != @device_id do %>
                <button
                  phx-click="save_file"
                  phx-value-id={transfer.id}
                  class="w-8 h-8 rounded-full bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 flex items-center justify-center hover:scale-110 transition-transform shadow-sm"
                  title="Download File"
                >
                  <i class="ph-bold ph-download-simple"></i>
                </button>
              <% end %>
              <button
                phx-click="remove_transfer"
                phx-value-id={transfer.id}
                class="w-8 h-8 rounded-full hover:bg-slate-200 dark:hover:bg-slate-700 flex items-center justify-center text-slate-400 hover:text-red-500 transition-colors"
              >
                <i class="ph-bold ph-x"></i>
              </button>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
