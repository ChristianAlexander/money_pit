defmodule MoneyPit.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        MoneyPit.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:money_pit, :token_signing_secret)
  end
end
