defmodule AppcuesIncrement.Config do
  def appcues_strategy do
    Application.fetch_env!(:appcues_increment, :strategy)
  end

  def kvs_processes do
    # TODO: improve this with Node.list()
    5
  end

  def sync_interval do
    Application.fetch_env!(:appcues_increment, :sync_interval)
  end
end

# phash to choose 1 from N servers
# list with logs
# every 5 seconds sync with db every key
# :erlang.phash2("bin", System.schedulers())
# TODO: make it scalable by using groups gproc2
