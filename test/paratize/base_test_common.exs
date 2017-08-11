defmodule Paratize.BaseTest.Common do

  defmacro __using__([test_impl: test_impl]) do
    quote location: :keep do
      doctest unquote(test_impl)

      def test_impl, do: unquote(test_impl)



      test "parallel_each/3 is able to execute the task in parallel and returns :ok." do
        args = [1,2,3,4,5]
        {:ok, store_pid} = Agent.start_link(fn-> [] end)
        worker_fun = fn(arg) ->
          Agent.update(store_pid, fn(item) -> [arg|item] end)
          :timer.sleep(100)
          arg * 2
        end

        {time, result} = :timer.tc fn ->
          args |> test_impl().parallel_each(worker_fun, %Paratize.TaskOptions{size: 2})
        end

        assert MapSet.equal?(
          Agent.get(store_pid, &(&1)) |> Enum.into(MapSet.new),
          [5,4,3,2,1] |> Enum.into(MapSet.new))
        assert result == :ok
        assert div(time, 1000) in 300..500
      end

      test "parallel_map/3 is able to execute the task in parallel and return the list of results" do
        args = [1,2,3,4,5]
        {:ok, store_pid} = Agent.start_link(fn-> [] end)
        worker_fun = fn(arg) ->
          Agent.update(store_pid, fn(item) -> [arg|item] end)
          :timer.sleep(100)
          arg * 2
        end

        {time, result} = :timer.tc fn ->
          args |> test_impl().parallel_map(worker_fun, %Paratize.TaskOptions{size: 2})
        end

        assert MapSet.equal?(
          Agent.get(store_pid, &(&1)) |> Enum.into(MapSet.new),
          [5,4,3,2,1] |> Enum.into(MapSet.new))
        assert result == [2,4,6,8,10]
        assert div(time, 1000) in 300..500
      end

      test "parallel_map does not over flatten arrays 1." do
        fn1 = fn a -> [a] end
        args1 = [1,2,3,4,5]
        result1 = args1 |> test_impl().parallel_map(fn1, %Paratize.TaskOptions{size: 2})

        assert MapSet.equal?(
          args1 |> Enum.map(fn1) |> Enum.into(MapSet.new),
          result1 |> Enum.into(MapSet.new))

        fn2 = fn a -> a ++ 1 end
        args2 = result1
        result2 = args2 |> test_impl().parallel_map(fn2, %Paratize.TaskOptions{size: 2})

        assert MapSet.equal?(
          args2 |> Enum.map(fn2) |> Enum.into(MapSet.new),
          result2 |> Enum.into(MapSet.new))

        fn3 = fn a -> a ++ 1 end
        args3 = [[1,2,3,4,5]]
        result3 = args3 |> test_impl().parallel_map(fn3, %Paratize.TaskOptions{size: 2})

        assert MapSet.equal?(
          args3 |> Enum.map(fn3) |> Enum.into(MapSet.new),
          result3 |> Enum.into(MapSet.new))

      end
    end
  end

end
