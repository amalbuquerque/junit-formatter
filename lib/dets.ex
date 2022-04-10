defmodule JUnitFormatter.Dets do
  @moduledoc """
  A helper module to wrap the Dets operations.
  """

  @type dets_name :: atom()
  @type key :: atom()
  @type value :: any()
  @type update_function :: (any() -> any())

  @spec new!(dets_name, Keyword.t()) :: {:ok, dets_name} | {:error, term()}
  def new!(name, opts \\ []) when is_atom(name) do
    # delete if there is a previous dets
    name
    |> to_string()
    |> File.rm()

    {:ok, dets} = :dets.open_file(name, opts)

    dets
  end

  @spec close_and_delete!(dets_name) :: :ok | {:error, term()}
  def close_and_delete!(name) do
    result = :dets.close(name)

    name
    |> to_string()
    |> File.rm()

    result
  end

  @spec update(dets_name, key, any(), update_function) :: :ok
  def update(dets, key, value, update_function) do
    new_value = case :dets.lookup(dets, key) do
      [] ->
        value

      [{^key, existing_value}] ->
        update_function.(existing_value)
    end

    :dets.insert(dets, {key, new_value})
  end

  @spec all(dets_name) :: term() | {:error, any()}
  def all(dets) do
    :dets.foldl(fn element, acc -> [element | acc] end, [], dets)
  end

  @spec lookup(dets_name, any()) :: nil | any() | [any()]
  def lookup(dets, key) do
    case :dets.lookup(dets, key) do
      [] -> nil

      [{^key, value}] ->
        value

      # when Dets allow to store more than one element
      # with the same key
      matches ->
        Enum.map(matches, fn {_k, v} -> v end)
    end
  end
end
