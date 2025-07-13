defmodule MoneyPitWeb.OrderDetailsLive do
  use MoneyPitWeb, :live_view

  on_mount {MoneyPitWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"id" => order_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MoneyPit.PubSub, "orders:updated:#{order_id}")
    end

    {:ok,
     socket
     |> assign(:order_id, order_id)
     |> assign(:order, nil)
     |> assign(:page_title, "Order Details")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, load_order(socket)}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "orders:" <> _,
          event: _event,
          payload: notification
        },
        socket
      ) do
    # Load the product relationship on the order from the notification
    order = Ash.load!(notification.data, :product, actor: socket.assigns.current_user)

    {:noreply, assign(socket, :order, order)}
  end

  @impl true
  def handle_event("refund", %{"id" => order_id}, socket) do
    case MoneyPit.Commerce.refund_order(order_id, actor: socket.assigns.current_user) do
      {:ok, _order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Refund request submitted successfully!")
         |> load_order()}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Failed to refund")}
    end
  end

  defp load_order(socket) do
    case MoneyPit.Commerce.get_order(socket.assigns.order_id,
           actor: socket.assigns.current_user,
           load: [:product]
         ) do
      {:ok, order} ->
        assign(socket, :order, order)

      {:error, _} ->
        socket
        |> put_flash(:error, "Order not found")
        |> push_navigate(to: ~p"/orders")
    end
  end

  defp get_order_steps(state) do
    base_steps = [
      %{
        id: :created,
        title: "Order Placed",
        description: "Your order has been received",
        step_number: 1
      },
      %{
        id: :paid,
        title: "Payment Processed",
        description: "Payment has been successfully processed",
        step_number: 2
      }
    ]

    case state do
      :created -> mark_steps_status(base_steps, :created)
      :paid -> mark_steps_status(base_steps, :paid)
      :failed -> add_failed_step(base_steps)
      :ready_for_refund -> add_refund_steps(base_steps, :ready_for_refund)
      :refunded -> add_refund_steps(base_steps, :refunded)
    end
  end

  defp mark_steps_status(steps, current_state) do
    Enum.map(steps, fn step ->
      cond do
        step.id == current_state ->
          Map.put(step, :status, :current)

        step_order(step.id) < step_order(current_state) ->
          Map.put(step, :status, :completed)

        true ->
          Map.put(step, :status, :pending)
      end
    end)
  end

  defp add_failed_step(steps) do
    failed_step = %{
      id: :failed,
      title: "Payment Failed",
      description: "There was an issue processing your payment",
      step_number: 2,
      status: :error
    }

    # Only show the "Order Placed" step as completed, then the failed step
    [
      %{
        id: :created,
        title: "Order Placed",
        description: "Your order has been received",
        step_number: 1,
        status: :completed
      },
      failed_step
    ]
  end

  defp add_refund_steps(steps, current_state) do
    refund_steps = [
      %{
        id: :ready_for_refund,
        title: "Refund Requested",
        description: "Your refund request is being processed",
        step_number: 3
      },
      %{
        id: :refunded,
        title: "Refunded",
        description: "Your refund has been processed",
        step_number: 4
      }
    ]

    # Mark all base steps as completed since we're in refund flow
    completed_base_steps = Enum.map(steps, &Map.put(&1, :status, :completed))

    refund_steps_with_status =
      Enum.map(refund_steps, fn step ->
        cond do
          step.id == current_state ->
            Map.put(step, :status, :completed)

          step_order_refund(step.id) < step_order_refund(current_state) ->
            Map.put(step, :status, :completed)

          true ->
            Map.put(step, :status, :pending)
        end
      end)

    completed_base_steps ++ refund_steps_with_status
  end

  defp step_order(:created), do: 1
  defp step_order(:paid), do: 2

  defp step_order_refund(:ready_for_refund), do: 1
  defp step_order_refund(:refunded), do: 2

  defp format_state_badge(:created), do: {"Processing", "badge-warning"}
  defp format_state_badge(:paid), do: {"Paid", "badge-success"}
  defp format_state_badge(:failed), do: {"Failed", "badge-error"}
  defp format_state_badge(:ready_for_refund), do: {"Refund Pending", "badge-info"}
  defp format_state_badge(:refunded), do: {"Refunded", "badge-neutral"}

  defp can_refund?(order, actor), do: MoneyPit.Commerce.can_refund_order?(actor, order)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto p-6">
        <div class="mb-8">
          <.link navigate={~p"/orders"} class="btn btn-ghost btn-sm mb-4">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Orders
          </.link>

          <h1 class="text-3xl font-bold text-gray-900 mb-2">Order Details</h1>
          <p class="text-gray-600">Track your order progress</p>
        </div>

        <div :if={@order} class="space-y-8">
          <div class="mb-6">
            <h3 class="font-semibold text-lg mb-4">Order Progress</h3>
            <ul class="steps steps-vertical lg:steps-horizontal w-full">
              <li
                :for={step <- get_order_steps(@order.state)}
                class={[
                  "step",
                  step[:status] == :completed && "step-primary",
                  step[:status] == :current && "step-primary",
                  step[:status] == :error && "step-error"
                ]}
                data-content={step[:step_number]}
              >
                <div class="text-left">
                  <div class="font-medium">{step.title}</div>
                  <div class="text-sm text-gray-500">{step.description}</div>
                </div>
              </li>
            </ul>
          </div>

          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <div class="flex justify-between items-start mb-6">
                <div>
                  <h2 class="card-title text-2xl mb-2">Order #{String.slice(@order.id, 0, 8)}</h2>
                  <p class="text-sm text-gray-500">
                    Placed on {Calendar.strftime(@order.inserted_at, "%B %d, %Y at %I:%M %p")}
                  </p>
                </div>
                <div class="text-right">
                  <% {status_text, badge_class} = format_state_badge(@order.state) %>
                  <div class={"badge " <> badge_class <> " badge-lg"}>{status_text}</div>
                </div>
              </div>
              
    <!-- Product Details -->
              <div class="bg-base-200 rounded-lg p-4 mb-6">
                <h3 class="font-semibold text-lg mb-2">{@order.product.name}</h3>
                <div class="flex justify-between items-center">
                  <span class="text-gray-600">Amount</span>
                  <span class="font-bold text-xl text-success">
                    {Money.to_string!(@order.amount)}
                  </span>
                </div>
              </div>
              
    <!-- Action Buttons -->
              <div class="card-actions justify-end">
                <.button
                  :if={can_refund?(@order, @current_user)}
                  phx-click="refund"
                  phx-value-id={@order.id}
                  phx-disable-with="Processing..."
                  class="btn-outline"
                >
                  Refund
                </.button>
              </div>
            </div>
          </div>

          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title">Need Help?</h3>
              <p class="text-sm text-gray-600 mb-4">
                If you have questions about your order, we're here to help.
              </p>
              <div class="space-y-2">
                <p class="text-sm">
                  <span class="font-medium">Order ID:</span>
                  <span class="font-mono">{@order.id}</span>
                </p>
                <p class="text-sm">
                  <span class="font-medium">Support:</span> moneypit@example.com
                </p>
              </div>
            </div>
          </div>
        </div>

        <div :if={!@order} class="text-center py-12">
          <div class="loading loading-spinner loading-lg"></div>
          <p class="mt-4 text-gray-500">Loading order details...</p>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
