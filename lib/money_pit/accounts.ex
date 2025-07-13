defmodule MoneyPit.Accounts do
  use Ash.Domain, otp_app: :money_pit, extensions: [AshAdmin.Domain]

  resources do
    resource MoneyPit.Accounts.Token
    resource MoneyPit.Accounts.User
  end
end
