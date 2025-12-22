defmodule AetherDropWeb.RoomLive.Index do
  use AetherDropWeb, :live_view
  alias AetherDropWeb.AppComponents
  alias AetherDropWeb.Presence

  @impl true
  def mount(%{"slug" => room_slug}, _session, socket) do
    # 1. Identity Management
    # Randomize position for Radar
    {x, y} = {Enum.random(10..90), Enum.random(10..90)}

    device = %{
      id: Nanoid.generate(),
      name: "Anonymous Device",
      type: :desktop,
      x: x,
      y: y,
      stealth_mode: false,
      quick_save: false
    }

    if connected?(socket) do
      Phoenix.PubSub.subscribe(AetherDrop.PubSub, "room:" <> room_slug)
      {:ok, _} = Presence.track(self(), "room:" <> room_slug, device.id, device)
    end

    {:ok,
     socket
     |> assign(:room_slug, room_slug)
     |> assign(:device, device)
     |> assign(:active_tab, "files")
     |> assign(:bridge_mode, false)
     |> assign(:show_settings, false)
     |> assign(:show_qr, false)
     |> assign(:show_mobile_menu, false)
     |> assign(:devices_nearby, [])
     |> assign(:transfers, [])
     |> assign(:messages, [])
     |> assign(:selected_peer_id, nil)
     |> assign(:unread_chat_count, 0)
     |> assign(:unread_files_count, 0)
     |> assign(:is_scanning, false)
     |> assign(:room_url, "")
     |> assign(:qr_svg, "")
     |> assign(:connecting_peer_id, nil)
     |> assign(:connected_peer_ids, MapSet.new())
     |> assign(:insecure_context, false)
     |> assign(:page_title, "Wondrop Room: " <> room_slug)}
  end

  @impl true
  def mount(_params, _session, socket) do
    # Redirect to a random room if no slug provided
    random_slug = Nanoid.generate()
    {:ok, push_navigate(socket, to: ~p"/r/#{random_slug}")}
  end

  @impl true
  def handle_params(params, url, socket) do
    room_url = smart_url(url, socket.assigns.room_slug)

    {:noreply,
     socket
     |> assign(:room_url, room_url)
     |> assign(:is_local, local_network?(url))
     |> assign(:qr_svg, generate_qr_svg(room_url))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Wondrop")
  end

  defp apply_action(socket, :room, _params) do
    socket
    |> assign(:page_title, "Wondrop Room: " <> socket.assigns.room_slug)
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :active_tab, tab)

    socket =
      if tab == "chat" do
        assign(socket, :unread_chat_count, 0)
      else
        socket
      end

    socket =
      if tab == "files" do
        assign(socket, :unread_files_count, 0)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("toggle_bridge", _params, socket) do
    new_mode = !socket.assigns.bridge_mode

    # Push to session:save so it persists
    socket =
      socket
      |> assign(:bridge_mode, new_mode)
      |> push_event("session:save", Map.put(socket.assigns.device, :bridge_mode, new_mode))

    {:noreply, socket}
  end

  def handle_event("toggle_settings", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_mobile_menu, false)
     |> assign(:show_settings, !socket.assigns.show_settings)}
  end

  def handle_event("toggle_qr", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_mobile_menu, false)
     |> assign(:show_qr, !socket.assigns.show_qr)}
  end

  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  def handle_event("bridge:auto_switch", %{"reason" => reason}, socket) do
    if !socket.assigns.bridge_mode do
      msg =
        case reason do
          "no_peers" ->
            "No nearby devices found. Switching to Bridge Mode to ensure delivery."

          "timeout" ->
            "Connection timed out. Switched to Bridge Mode for reliability."

          "insecure_context" ->
            "Direct P2P is unavailable on this connection (Insecure Context). Switching to Bridge Mode Relay."

          _ ->
            "Switched to Bridge Mode for a more reliable connection."
        end

      socket =
        socket
        |> assign(:bridge_mode, true)
        |> assign(:connecting_peer_id, nil)
        |> put_flash(:info, msg)
        |> push_event("session:save", %{bridge_mode: true})

      {:noreply, socket}
    else
      {:noreply, assign(socket, :connecting_peer_id, nil)}
    end
  end

  def handle_event("save_settings", params, socket) do
    name = params["name"]
    stealth_mode = params["stealth_mode"] == "on"
    quick_save = params["quick_save"] == "on"

    new_device =
      Map.merge(socket.assigns.device, %{
        name: name,
        stealth_mode: stealth_mode,
        quick_save: quick_save
      })

    {:ok, _} =
      Presence.update(self(), "room:" <> socket.assigns.room_slug, new_device.id, new_device)

    {:noreply,
     socket
     |> assign(:device, new_device)
     |> push_event("session:save", Map.put(new_device, :bridge_mode, socket.assigns.bridge_mode))}
  end

  def handle_event("save_and_close_settings", params, socket) do
    {:noreply, socket} = handle_event("save_settings", params, socket)
    {:noreply, assign(socket, :show_settings, false)}
  end

  def handle_event("scan", _params, socket) do
    send(self(), {:flash_radar})
    {:noreply, socket}
  end

  # Session Persistence Events
  def handle_event("session:restore", params, socket) do
    restored_device =
      Map.merge(socket.assigns.device, %{
        id: params["id"],
        name: params["name"],
        stealth_mode: params["stealth_mode"],
        quick_save: params["quick_save"]
      })

    # Restore Bridge Mode if it was explicitly saved
    socket =
      if Map.has_key?(params, "bridge_mode"),
        do: assign(socket, :bridge_mode, params["bridge_mode"]),
        else: socket

    # Untrack the temporary "Anonymous" device generated in mount
    Presence.untrack(self(), "room:" <> socket.assigns.room_slug, socket.assigns.device.id)

    # Track the restored device identity
    {:ok, _} =
      Presence.track(
        self(),
        "room:" <> socket.assigns.room_slug,
        restored_device.id,
        restored_device
      )

    {:noreply, assign(socket, :device, restored_device)}
  end

  def handle_event("session:request_init", _params, socket) do
    {:noreply,
     push_event(
       socket,
       "session:save",
       Map.put(socket.assigns.device, :bridge_mode, socket.assigns.bridge_mode)
     )}
  end

  # WebRTC Signaling
  @impl true
  def handle_event("send_signal", %{"recipient_id" => recipient_id, "signal" => signal}, socket) do
    Phoenix.PubSub.broadcast(
      AetherDrop.PubSub,
      "room:" <> socket.assigns.room_slug,
      {:signal,
       %{
         sender_id: socket.assigns.device.id,
         recipient_id: recipient_id,
         signal: signal
       }}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("clipboard:push", %{"content" => content}, socket) do
    content = String.trim(content)

    if content != "" do
      Phoenix.PubSub.broadcast(
        AetherDrop.PubSub,
        "room:" <> socket.assigns.room_slug,
        {:clipboard, %{sender_id: socket.assigns.device.id, content: content}}
      )

      {:noreply, put_flash(socket, :info, "Text pushed to other devices!")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("chat:send", %{"content" => content}, socket) do
    content = String.trim(content)

    if content != "" do
      msg = %{
        id: Nanoid.generate(),
        sender_id: socket.assigns.device.id,
        sender_name: socket.assigns.device.name,
        content: content,
        timestamp: DateTime.utc_now()
      }

      Phoenix.PubSub.broadcast(
        AetherDrop.PubSub,
        "room:" <> socket.assigns.room_slug,
        {:chat_msg, msg}
      )

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("phx-p2p-signal", %{"receiver_id" => receiver_id, "signal" => signal}, socket) do
    Phoenix.PubSub.broadcast(
      AetherDrop.PubSub,
      "room:" <> socket.assigns.room_slug,
      {:p2p_signal,
       %{sender_id: socket.assigns.device.id, receiver_id: receiver_id, signal: signal}}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "file:offer",
        %{"id" => id, "filename" => filename, "size" => size, "type" => type},
        socket
      ) do
    transfer = %{
      id: id,
      sender_id: socket.assigns.device.id,
      filename: filename,
      size: size,
      type: type,
      state: :pending,
      progress: 0
    }

    Phoenix.PubSub.broadcast(
      AetherDrop.PubSub,
      "room:" <> socket.assigns.room_slug,
      {:file_offer, transfer}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "file:progress",
        %{"id" => id, "progress" => progress, "state" => state},
        socket
      ) do
    # Only send progress if NOT canceled (optional check, transfers list is source of truth)
    Phoenix.PubSub.broadcast(
      AetherDrop.PubSub,
      "room:" <> socket.assigns.room_slug,
      {:file_progress, %{id: id, progress: progress, state: state}}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("file:bridge_chunk", %{"metadata" => metadata, "chunk" => chunk}, socket) do
    Phoenix.PubSub.broadcast(
      AetherDrop.PubSub,
      "room:" <> socket.assigns.room_slug,
      {:file_bridge_chunk,
       %{sender_id: socket.assigns.device.id, metadata: metadata, chunk: chunk}}
    )

    {:noreply, socket}
  end

  def handle_event("peer_connected", %{"peer_id" => peer_id}, socket) do
    {:noreply,
     socket
     |> assign(:connecting_peer_id, nil)
     |> update(:connected_peer_ids, &MapSet.put(&1, peer_id))
     |> put_flash(:info, "Connected reached for peer #{peer_id}")}
  end

  def handle_event("select_device", %{"id" => peer_id}, socket) do
    {:noreply,
     socket
     |> assign(:selected_peer_id, peer_id)
     |> assign(:connecting_peer_id, peer_id)
     |> push_event("initiate_peer", %{peer_id: peer_id})}
  end

  def handle_event("save_file", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "trigger_save", %{id: id})}
  end

  def handle_event("file:accept", %{"id" => id}, socket) do
    Phoenix.PubSub.broadcast(
      AetherDrop.PubSub,
      "room:" <> socket.assigns.room_slug,
      {:file_accepted, %{id: id, receiver_id: socket.assigns.device.id}}
    )

    {:noreply, socket}
  end

  def handle_event("remove_transfer", %{"id" => id}, socket) do
    # 1. Inform everyone that this transfer is dead
    Phoenix.PubSub.broadcast(
      AetherDrop.PubSub,
      "room:" <> socket.assigns.room_slug,
      {:file_cancel, %{id: id, canceled_by: socket.assigns.device.id}}
    )

    # 2. Update local state
    transfers = Enum.reject(socket.assigns.transfers, fn t -> t.id == id end)
    {:noreply, assign(socket, :transfers, transfers)}
  end

  def handle_event("clear_transfers", _params, socket) do
    {:noreply, assign(socket, :transfers, [])}
  end

  def handle_event("peer_error", %{"error" => msg}, socket) do
    {:noreply,
     socket
     |> assign(:connecting_peer_id, nil)
     |> put_flash(:error, "Peer Error: #{msg}")}
  end

  def handle_event("insecure_context_detected", _params, socket) do
    if connected?(socket) do
      Process.send_after(self(), :dismiss_insecure_warning, 8000)
    end

    {:noreply, assign(socket, :insecure_context, true)}
  end

  # --- Handle Info / PubSub Messages ---

  @impl true
  def handle_info({:clipboard, %{sender_id: sender_id, content: content}}, socket) do
    if sender_id != socket.assigns.device.id do
      {:noreply, push_event(socket, "clipboard:sync", %{content: content})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {:p2p_signal, %{sender_id: sender_id, receiver_id: receiver_id, signal: signal}},
        socket
      ) do
    if receiver_id == socket.assigns.device.id do
      {:noreply, push_event(socket, "phx-p2p-signal", %{sender_id: sender_id, signal: signal})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:file_bridge_chunk, payload}, socket) do
    {:noreply, push_event(socket, "file:bridge_chunk", payload)}
  end

  @impl true
  def handle_info({:file_offer, transfer}, socket) do
    transfers =
      case Enum.find(socket.assigns.transfers, &(&1.id == transfer.id)) do
        nil -> [transfer | socket.assigns.transfers]
        _ -> socket.assigns.transfers
      end

    socket = assign(socket, :transfers, transfers)

    socket =
      if socket.assigns.active_tab != "files" do
        update(socket, :unread_files_count, &(&1 + 1))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:file_accepted, payload}, socket) do
    {:noreply, push_event(socket, "file:approved", payload)}
  end

  @impl true
  def handle_info({:file_progress, %{id: id, progress: progress, state: state}}, socket) do
    # Don't update progress if the transfer was already removed from local state
    if Enum.any?(socket.assigns.transfers, &(&1.id == id)) do
      state_atom =
        case state do
          "completed" -> :completed
          "sending" -> :sending
          _ -> :sending
        end

      transfers =
        Enum.map(socket.assigns.transfers, fn t ->
          if t.id == id do
            Map.merge(t, %{progress: progress, state: state_atom})
          else
            t
          end
        end)

      {:noreply, assign(socket, :transfers, transfers)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:file_cancel, %{id: id, canceled_by: canceled_by}}, socket) do
    # Update local UI
    transfers = Enum.reject(socket.assigns.transfers, fn t -> t.id == id end)

    # Notify JS Hook to stop processing/reading
    socket =
      socket
      |> assign(:transfers, transfers)
      |> push_event("file:cancel", %{id: id})

    # Show flash if someone else canceled your transfer
    socket =
      if canceled_by != socket.assigns.device.id do
        put_flash(socket, :info, "A transfer was canceled by the other party.")
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_msg, msg}, socket) do
    socket = update(socket, :messages, fn msgs -> [msg | msgs] end)

    socket =
      if socket.assigns.active_tab != "chat" do
        update(socket, :unread_chat_count, &(&1 + 1))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    # Cleanup connected_peer_ids if they left
    leaves = Map.keys(payload.leaves)

    connected_peer_ids =
      Enum.reduce(leaves, socket.assigns.connected_peer_ids, fn id, acc ->
        MapSet.delete(acc, id)
      end)

    {:noreply,
     socket
     |> assign(:devices_nearby, get_nearby_devices(socket))
     |> assign(:connected_peer_ids, connected_peer_ids)}
  end

  @impl true
  def handle_info({:flash_radar}, socket) do
    Process.send_after(self(), :stop_scan, 1000)

    {:noreply,
     socket
     |> assign(:is_scanning, true)
     |> assign(:devices_nearby, get_nearby_devices(socket))}
  end

  @impl true
  def handle_info(:stop_scan, socket) do
    {:noreply, assign(socket, :is_scanning, false)}
  end

  @impl true
  def handle_info(
        {:signal, %{recipient_id: recipient_id, sender_id: sender_id, signal: signal}},
        socket
      ) do
    if recipient_id == socket.assigns.device.id do
      {:noreply, push_event(socket, "phx-p2p-signal", %{sender_id: sender_id, signal: signal})}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:initiate_peer, peer_id}, socket) do
    {:noreply,
     push_event(socket, "initiate_peer", %{
       peer_id: peer_id,
       initiator_id: socket.assigns.device.id
     })}
  end

  def handle_info(:dismiss_insecure_warning, socket) do
    {:noreply, assign(socket, :insecure_context, false)}
  end

  # Helper Functions

  defp get_nearby_devices(socket) do
    Presence.list("room:" <> socket.assigns.room_slug)
    |> Map.reject(fn {key, _} -> key == socket.assigns.device.id end)
    |> Enum.map(fn {_id, %{metas: [meta | _]}} -> meta end)
    |> Enum.reject(fn d -> Map.get(d, :stealth_mode, false) end)
  end

  defp smart_url(url, _room_slug) do
    uri = URI.parse(url)

    if uri.host in ["localhost", "127.0.0.1"] do
      lan_ip = get_lan_ip()
      # Reconstruct URL with LAN IP
      %URI{uri | host: lan_ip} |> URI.to_string()
    else
      url
    end
  end

  defp get_lan_ip do
    case :inet.getifaddrs() do
      {:ok, ifaddrs} ->
        ifaddrs
        |> Enum.flat_map(fn {_, opts} -> Keyword.get_values(opts, :addr) end)
        |> Enum.filter(fn
          {127, 0, 0, 1} -> false
          {192, 168, _, _} -> true
          {10, _, _, _} -> true
          {172, _, _, _} -> true
          # Link-local/Ad-hoc IP
          {169, 254, _, _} -> true
          _ -> false
        end)
        # Prioritize the first valid LAN IP found
        |> List.first()
        |> case do
          nil -> "localhost"
          addr -> addr |> Tuple.to_list() |> Enum.join(".")
        end

      _ ->
        "localhost"
    end
  end

  defp generate_qr_svg(url) do
    url
    |> EQRCode.encode()
    |> EQRCode.svg(viewbox: true)
  end

  defp local_network?(url) do
    uri = URI.parse(url)
    host = uri.host

    host in ["localhost", "127.0.0.1"] or
      Regex.match?(~r/^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|169\.254\.)/, host)
  end
end
