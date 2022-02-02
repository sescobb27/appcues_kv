defmodule AppcuesIncrement.Repo do
  use Ecto.Repo,
    otp_app: :appcues_increment,
    adapter: Ecto.Adapters.Postgres
end
