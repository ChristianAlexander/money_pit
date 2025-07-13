defmodule MoneyPitWeb.PageController do
  use MoneyPitWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
