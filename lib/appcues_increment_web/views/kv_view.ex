defmodule AppcuesIncrementWeb.KVView do
  use AppcuesIncrementWeb, :view

  def render("show.json", %{key: key, value: value}) do
    %{[key] => value}
  end
end
