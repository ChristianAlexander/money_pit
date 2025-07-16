defmodule MoneyPit.Commerce.Changes.Sleep do
  use Ash.Resource.Change

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      Process.sleep(:rand.uniform(5_000) + 2_000)

      changeset
    end)
  end
end
