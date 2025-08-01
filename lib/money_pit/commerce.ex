defmodule MoneyPit.Commerce do
  use Ash.Domain,
    otp_app: :money_pit

  resources do
    resource MoneyPit.Commerce.Product do
      define :create_product, action: :create
      define :list_products, action: :read
      define :get_product, action: :read, get_by: [:id]
    end

    resource MoneyPit.Commerce.Order do
      define :purchase_product, action: :purchase_product
      define :list_orders, action: :read
      define :get_order, action: :read, get_by: [:id]
      define :refund_order, action: :refund
    end
  end
end
