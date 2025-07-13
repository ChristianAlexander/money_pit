defmodule MoneyPitWeb.ErrorJSONTest do
  use MoneyPitWeb.ConnCase, async: true

  test "renders 404" do
    assert MoneyPitWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert MoneyPitWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
