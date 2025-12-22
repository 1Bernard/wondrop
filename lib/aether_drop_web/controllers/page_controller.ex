defmodule AetherDropWeb.PageController do
  use AetherDropWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def up(conn, _params) do
    send_resp(conn, 200, "OK")
  end
end
