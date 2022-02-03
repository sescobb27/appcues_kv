defmodule AppcuesIncrement.KV.Strategy do
  @callback increment(key :: String.t(), value :: non_neg_integer()) :: :ok | {:error, term()}
end
