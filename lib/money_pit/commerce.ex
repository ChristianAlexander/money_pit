defmodule MoneyPit.Commerce do
  use Ash.Domain,
    otp_app: :money_pit

  resources do
    resource MoneyPit.Commerce.Product
  end
end
