defmodule MoneyPit.Commerce.Order do
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    otp_app: :money_pit,
    domain: MoneyPit.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshOban],
    notifiers: [Ash.Notifier.PubSub]

  postgres do
    table "orders"
    repo MoneyPit.Repo
  end

  oban do
    triggers do
      # Payments are processed immediately after an order is created
      trigger :process_payment do
        action :process_payment
        queue :default
        scheduler_cron false
        worker_module_name MoneyPit.Commerce.Order.AshOban.Worker.ProcessPayment
        scheduler_module_name MoneyPit.Commerce.Order.AshOban.Scheduler.ProcessPayment
        where expr(state == :created)
      end

      # Refunds are processed every minute, which is the default schedule for AshOban triggers
      trigger :perform_refunds do
        action :perform_refund
        queue :default
        where expr(state == :ready_for_refund)
        worker_module_name MoneyPit.Commerce.Order.AshOban.Worker.PerformRefunds
        scheduler_module_name MoneyPit.Commerce.Order.AshOban.Scheduler.PerformRefunds
      end
    end
  end

  actions do
    defaults [:read]

    create :purchase_product do
      accept [:product_id]

      change relate_actor(:user)
      change set_attribute(:amount, "$0.00")

      # Automatically set the amount based on the product price
      change before_action(fn changeset, context ->
               product_id = Ash.Changeset.get_attribute(changeset, :product_id)
               product = MoneyPit.Commerce.get_product!(product_id, actor: context.actor)

               Ash.Changeset.force_change_attribute(changeset, :amount, product.price)
             end)

      change run_oban_trigger(:process_payment)
    end

    update :refund do
      change set_attribute(:state, :ready_for_refund)
    end

    update :process_payment do
      description "Process the payment for an order"

      require_atomic? false

      change MoneyPit.Commerce.Changes.Sleep

      change fn changeset, _ ->
        if :rand.uniform() > 0.1 do
          # Simulate a successful payment 90% of the time
          Ash.Changeset.change_attribute(changeset, :state, :paid)
        else
          Ash.Changeset.change_attribute(changeset, :state, :failed)
        end
      end
    end

    update :perform_refund do
      description "Perform a refund for an order"

      require_atomic? false

      change MoneyPit.Commerce.Changes.Sleep
      change set_attribute(:state, :refunded)
    end
  end

  policies do
    bypass AshOban.Checks.AshObanInteraction do
      authorize_if action_type(:read)
      authorize_if action(:process_payment)
      authorize_if action(:perform_refund)
    end

    policy action_type(:read) do
      # Users can see their own orders
      authorize_if relates_to_actor_via(:user)

      # Admins can see all orders
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:refund) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end
  end

  pub_sub do
    module MoneyPitWeb.Endpoint

    prefix "orders"
    publish :purchase_product, [[:user_id, nil], "created"]
    publish_all :update, [[:user_id, nil], "updated", [:_pkey, nil]]
  end

  attributes do
    uuid_primary_key :id

    attribute :amount, :money do
      allow_nil? false
      public? true
    end

    attribute :state, :atom do
      constraints one_of: [:created, :paid, :failed, :ready_for_refund, :refunded]
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
