defmodule MixpanelTest.Queue.SimpleTest do
  use ExUnit.Case, async: true
  # , default_opts: [numtests: 500]
  use PropCheck

  alias Mixpanel.Queue.Simple

  property "a queue always has correct count" do
    forall {_limit, model, queue} <- queue() do
      assert Simple.length(queue) == model_length(model)
    end
  end

  property "a queue never overflows" do
    forall {limit, model, queue} <- queue() do
      length = Simple.length(queue)
      assert length >= 0
      assert length <= limit
      assert length == model_length(model)
    end
  end

  property "a queue always returns everything added" do
    forall {limit, model, queue} <- queue() do
      {_, queue} =
        for prefix <- Map.keys(model), reduce: {model, queue} do
          {model, queue} ->
            {entire_prefix, model} = Map.pop(model, prefix)
            assert {^entire_prefix, queue} = Simple.take(queue, prefix, limit)
            {model, queue}
        end

      assert Simple.length(queue) == 0
    end
  end

  property "queue always returns correct number of elements" do
    forall [{limit, model, orig_queue} <- queue(), batch_size <- limit()] do
      {queue, _, elements} =
        for prefix <- Map.keys(model), reduce: {orig_queue, model, []} do
          {queue, model, elements} ->
            take_all(queue, model, prefix, limit, batch_size, elements)
        end

      assert Simple.length(queue) == 0

      assert elements ==
               Enum.reduce(orig_queue, [], fn {_prefix, value}, acc -> acc ++ [value] end)
    end
  end

  defp prefix(), do: oneof([range(1, 10), integer()])
  defp val(), do: binary()
  defp limit(), do: integer(1, :inf)

  defp queue() do
    let [limit <- limit(), vicinity <- list({prefix(), val()})] do
      queue = Enum.into(vicinity, Simple.new(limit))
      model = model_queue(vicinity, limit)

      {limit, model, queue}
    end
  end

  defp model_queue(vicinity, limit) do
    {_, model} =
      Enum.reduce_while(
        vicinity,
        {0, %{}},
        fn
          {prefix, value}, {count, acc} when count < limit ->
            count = count + 1
            acc = Map.update(acc, prefix, [value], &[value | &1])
            {:cont, {count, acc}}

          _, acc ->
            {:halt, acc}
        end
      )

    for {prefix, values} <- model, into: %{} do
      {prefix, Enum.reverse(values)}
    end
  end

  defp model_length(model) do
    Map.values(model) |> List.flatten() |> Kernel.length()
  end

  defp take_all(queue, model, prefix, limit, batch_size, elements \\ []) do
    model_batch = Enum.take(model[prefix], min(batch_size, limit))
    model = Map.put(model, prefix, Enum.drop(model[prefix], length(model_batch)))

    assert {^model_batch, queue} = Simple.take(queue, prefix, batch_size)
    assert Simple.length(queue) == model_length(model)

    elements = elements ++ model_batch

    case length(model[prefix]) do
      0 -> {queue, model, elements}
      _ -> take_all(queue, model, prefix, limit, batch_size, elements)
    end
  end
end
