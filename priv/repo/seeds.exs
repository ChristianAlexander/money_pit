# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MoneyPit.Repo.insert!(%MoneyPit.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
MoneyPit.Commerce.create_product!(%{name: "Pro Plan", price: "19.99"}, authorize?: false)
MoneyPit.Commerce.create_product!(%{name: "Max Plan", price: "200.00"}, authorize?: false)

{:ok, hashed_password} = AshAuthentication.BcryptProvider.hash("password")

Ash.Seed.seed!(MoneyPit.Accounts.User, %{
  email: "admin@example.com",
  hashed_password: hashed_password,
  role: :admin
})

Ash.Seed.seed!(MoneyPit.Accounts.User, %{
  email: "user@example.com",
  hashed_password: hashed_password
})
