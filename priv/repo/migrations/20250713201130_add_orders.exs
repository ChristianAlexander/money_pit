defmodule MoneyPit.Repo.Migrations.AddOrders do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:orders, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :amount, :money_with_currency, null: false
      add :state, :text, null: false, default: "created"

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :user_id,
          references(:users,
            column: :id,
            name: "orders_user_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :product_id,
          references(:products,
            column: :id,
            name: "orders_product_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end
  end

  def down do
    drop constraint(:orders, "orders_user_id_fkey")

    drop constraint(:orders, "orders_product_id_fkey")

    drop table(:orders)
  end
end
