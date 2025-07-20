# MoneyPit

A demonstration of [AshStateMachine](https://hexdocs.pm/ash_state_machine/) - the state machine extension for the [Ash Framework](https://ash-hq.org/).


The companion to a YouTube video:

[![Watch the video](https://img.youtube.com/vi/_x6TE7hbE1k/maxresdefault.jpg)](https://youtu.be/_x6TE7hbE1k)

This e-commerce application showcases how to build robust, stateful business processes with automatic state transitions, validation, and background job integration.

### State Machine Features
- **Order State Transitions** - Orders flow through states: `created` → `paid`/`failed` → `ready_for_refund` → `refunded`
- **Automatic State Validation** - Invalid state transitions are prevented at the framework level
- **Background Job Integration** - State changes trigger background jobs using [AshOban](https://hexdocs.pm/ash_oban/)
- **Real-time Updates** - UI updates automatically as orders transition through states
- **Policy Integration** - Authorization rules based on current state (e.g., only admins can refund `paid` orders)

### Run it yourself!

1. **Install dependencies and set up the database:**
   ```bash
   mix setup
   ```
   This will:
   - Install Elixir dependencies
   - Set up the database with migrations
   - Create seed data with demo products and users
   - Install and build frontend assets

2. **Start the Phoenix server:**
   ```bash
   iex -S mix phx.server
   ```

3. **Visit the application:**
   - Main site: [`localhost:4000`](http://localhost:4000)
   - Storefront: [`localhost:4000/storefront`](http://localhost:4000/storefront) (requires login)
   - Orders: [`localhost:4000/orders`](http://localhost:4000/orders) (requires login)

## Demo Credentials & Data

### Demo Accounts
- **Regular User:** `user@example.com` / `password`
- **Admin User:** `admin@example.com` / `password`

### Demo Products
- **Pro Plan** - $19.99
- **Max Plan** - $200.00

### Key Technologies
- **[Ash State Machine](https://hexdocs.pm/ash_state_machine/)** - State machine extension
- **[Ash Framework](https://ash-hq.org/)** - Declarative application framework
- **[AshOban](https://hexdocs.pm/ash_oban/)** - Background job processing
- **[Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)** - Real-time web interfaces
- **[Ash Authentication](https://hexdocs.pm/ash_authentication/)** - Authentication system
