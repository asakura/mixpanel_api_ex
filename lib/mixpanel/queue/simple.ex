defmodule Mixpanel.Queue.Simple do
  @moduledoc """
  A simple queue implementation that uses zipper technique and discards elements
  when it's full.
  """
  @behaviour Mixpanel.Queue

  @type prefix :: atom
  @type zipper :: %{
          length: non_neg_integer,
          head: list,
          tail: list
        }
  @type t :: %__MODULE__{
          max_size: pos_integer,
          prefixes: %{required(prefix) => zipper}
        }

  defstruct max_size: 1, prefixes: %{default: %{length: 0, head: [], tail: []}}

  @dialyzer {:no_underspecs, new: 1}

  @impl Mixpanel.Queue
  @spec new(pos_integer) :: t
  def new(limit) when is_integer(limit) and limit > 0 do
    %__MODULE__{max_size: limit}
  end

  def new(limit),
    do: raise(ArgumentError, "limit must be greater than 0, got #{inspect(limit)}")

  @impl Mixpanel.Queue
  @spec push(t, prefix, any) :: {:ok, t} | :discarded
  def push(queue, prefix \\ :default, element)

  def push(%__MODULE__{max_size: max_size, prefixes: prefixes} = queue, prefix, element) do
    case __MODULE__.length(queue) >= max_size do
      false when is_map_key(prefixes, prefix) ->
        prefixes =
          queue.prefixes
          |> update_in([prefix, :length], &(&1 + 1))
          |> update_in([prefix, :tail], &[element | &1])

        {:ok, %__MODULE__{queue | prefixes: prefixes}}

      false ->
        {:ok,
         %__MODULE__{
           queue
           | prefixes:
               Map.put(
                 queue.prefixes,
                 prefix,
                 %{length: 1, head: [], tail: [element]}
               )
         }}

      true ->
        :discarded
    end
  end

  @impl Mixpanel.Queue
  @spec take(t, prefix, non_neg_integer) :: {list, t}
  def take(queue, prefix \\ :default, amount)

  def take(%__MODULE__{prefixes: prefixes} = queue, prefix, amount)
      when is_map_key(prefixes, prefix) do
    case get_in(prefixes, [prefix, :tail]) do
      [] ->
        case Enum.split(get_in(prefixes, [prefix, :head]), amount) do
          {result, []} ->
            {result, %__MODULE__{queue | prefixes: Map.delete(prefixes, prefix)}}

          {result, new_head} ->
            prefixes =
              prefixes
              |> update_in([prefix, :length], &(&1 - amount))
              |> update_in([prefix, :head], fn _ -> new_head end)

            {result, %__MODULE__{queue | prefixes: prefixes}}
        end

      tail ->
        prefixes =
          prefixes
          |> update_in([prefix, :head], &(&1 ++ Enum.reverse(tail)))
          |> update_in([prefix, :tail], fn _ -> [] end)

        take(%__MODULE__{queue | prefixes: prefixes}, prefix, amount)
    end
  end

  def take(%__MODULE__{} = queue, _prefix, _amount), do: {[], queue}

  @impl Mixpanel.Queue
  @spec length(t) :: non_neg_integer
  def length(%__MODULE__{prefixes: prefixes}) do
    for {_prefix, %{length: length}} <- prefixes, reduce: 0 do
      acc -> acc + length
    end
  end

  @spec length(t, prefix) :: non_neg_integer
  defp length(%{prefixes: prefixes}, prefix) do
    %{length: length} = prefixes[prefix]
    length
  end

  @spec elements(t, prefix) :: nonempty_maybe_improper_list
  defp elements(%{prefixes: prefixes}, prefix) do
    %{head: head, tail: tail} = prefixes[prefix]

    case tail do
      [] -> head
      _ -> head ++ Enum.reverse(tail)
    end
  end

  @doc ~S"""
  Returns an element at the given index, where index `0` is the head.
  Returns `:error` if index is out of bounds.
  """
  @spec at(t, prefix, non_neg_integer) :: {:ok, any} | :error
  def at(%__MODULE__{prefixes: prefixes} = queue, prefix \\ :default, index)
      when is_map_key(prefixes, prefix) do
    if length(queue, prefix) > index do
      item = Enum.at(elements(queue, prefix), index)
      {:ok, item}
    else
      :error
    end
  end

  @doc ~S"""
  Returns an element the given index, where index `0` is the head.
  Raises `ArgumentError` if index is out of bounds.
  """
  @spec at!(t, non_neg_integer) :: any
  def at!(%__MODULE__{} = queue, index) do
    case at(queue, index) do
      {:ok, item} -> item
      :error -> raise ArgumentError, "index #{index} out of bounds"
    end
  end

  @doc ~S"""
  Returns a list of all prefixes in the queue.
  """
  @spec prefixes(t) :: [prefix]
  def prefixes(%__MODULE__{prefixes: prefixes}), do: Map.keys(prefixes)
end

defimpl Collectable, for: Mixpanel.Queue.Simple do
  @spec into(@for.t()) :: {@for.t(), (@for.t, {:cont, any} | :done | :halt -> @for.t() | :ok)}
  def into(orig) do
    {orig,
     fn
       queue, {:cont, {prefix, item}} ->
         case @for.push(queue, prefix, item) do
           {:ok, queue} -> queue
           :discarded -> queue
         end

       queue, {:cont, item} ->
         case @for.push(queue, :default, item) do
           {:ok, queue} -> queue
           :discarded -> queue
         end

       queue, :done ->
         queue

       _, :halt ->
         :ok
     end}
  end
end

defimpl Enumerable, for: Mixpanel.Queue.Simple do
  @spec count(@for.t) :: {:ok, non_neg_integer}
  def count(queue),
    do: {:ok, @for.length(queue)}

  @spec member?(@for.t, term) :: {:error, module}
  def member?(_queue, _item),
    do: {:error, __MODULE__}

  @spec reduce(@for.t, Enumerable.acc(), Enumerable.reducer()) :: Enumerable.result()
  def reduce(_queue, {:halt, acc}, _fun),
    do: {:halted, acc}

  def reduce(queue, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(queue, &1, fun)}

  def reduce(queue, {:cont, acc}, fun) do
    case @for.length(queue) do
      0 ->
        {:done, acc}

      _ ->
        [prefix | _] = @for.prefixes(queue)
        {[item], queue} = @for.take(queue, prefix, 1)
        reduce(queue, fun.({:default, item}, acc), fun)
    end
  end

  @spec slice(@for.t) ::
          {:ok, size :: non_neg_integer(), Enumerable.slicing_fun() | Enumerable.to_list_fun()}
  def slice(queue) do
    {:ok, @for.length(queue),
     fn
       _start, 0 ->
         []

       start, len ->
         Enum.reduce((start + len - 1)..start, [], fn index, acc ->
           {:ok, item} = @for.at(queue, index)
           [item | acc]
         end)
     end}
  end
end
