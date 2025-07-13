defmodule MoneyPit.Commerce.Order do
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    otp_app: :money_pit,
    domain: MoneyPit.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "orders"
    repo MoneyPit.Repo
  end

  actions do
    defaults [:read]

    create :purchase_product do
      accept [:product_id]

      change relate_actor(:user)
      change set_attribute(:amount, "$0.00")

      change before_action(fn changeset, context ->
               product_id = Ash.Changeset.get_attribute(changeset, :product_id)
               product = MoneyPit.Commerce.get_product!(product_id, actor: context.actor)

               Ash.Changeset.force_change_attribute(changeset, :amount, product.price)
             end)
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :amount, :money do
      allow_nil? false
      public? true
    end

    attribute :state, :atom do
      constraints one_of: [:created, :paid]
      default :created
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, MoneyPit.Accounts.User do
      allow_nil? false
      public? true
    end

    belongs_to :product, MoneyPit.Commerce.Product do
      allow_nil? false
      public? true
    end
  end
end
