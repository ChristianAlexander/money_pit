defmodule MoneyPit.Commerce.Order do
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    otp_app: :money_pit,
    domain: MoneyPit.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshOban]

  postgres do
    table "orders"
    repo MoneyPit.Repo
  end

  oban do
    triggers do
      trigger :process_payment do
        action :process_payment
        queue :default
        scheduler_cron false
        worker_module_name MoneyPit.Commerce.Order.AshOban.Worker.ProcessPayment
        scheduler_module_name MoneyPit.Commerce.Order.AshOban.Scheduler.ProcessPayment
        where expr(state == :created)
      end
    end
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

      change run_oban_trigger(:process_payment)
    end

    update :process_payment do
      description "Process the payment for an order"

      require_atomic? false

      change fn changeset, _ ->
        # Simulate a payment processing delay
        processing_milliseconds = :rand.uniform(5_000) + 2_000
        Process.sleep(processing_milliseconds)

        if :rand.uniform() > 0.1 do
          # Simulate a successful payment 90% of the time
          Ash.Changeset.change_attribute(changeset, :state, :paid)
        else
          Ash.Changeset.change_attribute(changeset, :state, :failed)
        end
      end
    end
  end

  policies do
    bypass AshOban.Checks.AshObanInteraction do
      authorize_if action_type(:read)
      authorize_if action(:process_payment)
    end

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
      constraints one_of: [:created, :paid, :failed]
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
