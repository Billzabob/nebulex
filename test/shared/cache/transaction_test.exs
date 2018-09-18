defmodule Nebulex.Cache.TransactionTest do
  import Nebulex.SharedTestCase

  deftests do
    test "transaction" do
      refute @cache.transaction(fn ->
               1
               |> @cache.set(11, return: :key)
               |> @cache.get!(return: :key)
               |> @cache.delete(return: :key)
               |> @cache.get()
             end)

      assert_raise MatchError, fn ->
        @cache.transaction(fn ->
          :ok =
            1
            |> @cache.set(11, return: :key)
            |> @cache.get!(return: :key)
            |> @cache.delete(return: :key)
            |> @cache.get()
        end)
      end
    end

    test "transaction aborted" do
      spawn_link(fn ->
        @cache.transaction(
          fn ->
            :timer.sleep(1100)
          end,
          keys: [1],
          retries: 1
        )
      end)

      :timer.sleep(200)

      assert_raise RuntimeError, "transaction aborted", fn ->
        @cache.transaction(
          fn ->
            @cache.get(1)
          end,
          keys: [1],
          retries: 1
        )
      end
    end

    test "in_transaction?" do
      refute @cache.in_transaction?()

      @cache.transaction(fn ->
        _ = @cache.set(1, 11, return: :key)
        true = @cache.in_transaction?()
      end)
    end
  end
end
