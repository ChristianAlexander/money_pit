defmodule MoneyPit.Commerce do
  use Ash.Domain,
    otp_app: :money_pit

  resources do
    resource MoneyPit.Commerce.Product do
      define :create_product, action: :create
      define :list_products, action: :read
      define :get_product, action: :read, get_by: [:id]
    end
  end
end
