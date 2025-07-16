defmodule MoneyPitWeb.StorefrontLive do
  use MoneyPitWeb, :live_view

  on_mount {MoneyPitWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :products, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, load_products(socket)}
  end

  @impl true
  def handle_event("purchase", %{"product_id" => product_id}, socket) do
    case MoneyPit.Commerce.purchase_product(
           %{product_id: product_id},
           actor: socket.assigns.current_user
         ) do
      {:ok, order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Order placed successfully! Your order is being processed.")
         |> push_navigate(to: ~p"/orders/#{order}")}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Failed to place order: #{inspect(error)}")}
    end
  end

  defp load_products(socket) do
    products = MoneyPit.Commerce.list_products!(actor: socket.assigns.current_user)
    assign(socket, :products, products)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-6xl mx-auto p-6">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content mb-2">MoneyPit</h1>
          <p class="text-base-content/70">What do you want to buy today?</p>
        </div>

        <div :if={@products == []} class="text-center py-12">
          <div class="text-base-content/50">
            <svg
              class="mx-auto h-24 w-24 text-base-content/40"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
              />
            </svg>
            <h3 class="mt-4 text-lg font-medium text-base-content">No products available</h3>
            <p class="mt-2 text-sm text-base-content/50">
              There are currently no products in the store.
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div :for={product <- @products} class="bg-base-100 rounded-lg shadow-md overflow-hidden">
            <div class="p-6">
              <h3 class="text-xl font-semibold text-base-content mb-2">{product.name}</h3>
              <div class="text-2xl font-bold text-success mb-4">
                {Money.to_string!(product.price)}
              </div>
              <.button
                :if={
                  MoneyPit.Commerce.can_purchase_product?(@current_user, %{product_id: product.id})
                }
                phx-click="purchase"
                phx-value-product_id={product.id}
                phx-disable-with="Ordering…"
                class="w-full btn-primary font-semibold py-2 px-4 rounded-lg transition-colors duration-200"
              >
                Purchase Now
              </.button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
