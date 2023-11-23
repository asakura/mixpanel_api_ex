defmodule Mixpanel.Queue do
  @moduledoc """
  A queue behaviour that allows to push elements under different prefixes
  and take them in the same order they were pushed.
  """

  @doc ~S"""
  Creates a new queue with the given limit of stored elements.
  """
  @callback new(pos_integer) :: any

  @doc ~S"""
  Pushes an element to the queue under `prefix` prefix. Returns `{:ok, queue}`
  if the element was added, or `:discarded` if the queue was full and the
  element was discarded.
  """
  @callback push(any, any, any) :: {:ok, any} | :discarded

  @doc ~S"""
  Takes `amount` elements from the queue under `prefix` prefix. Returns a tuple
  with a list of elements and the updated queue.
  """
  @callback take(any, any, non_neg_integer) :: {list, any}

  @doc ~S"""
  Returns the total number of elements in the queue.
  """
  @callback length(any) :: non_neg_integer
end
