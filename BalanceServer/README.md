# Balance Server

Self-hosted synchronization, account and web server for the Balance iOS, macOS, watchOS and Android applications. It is a single Go process with an embedded SQLite database and a complete browser client, and runs on Linux, Windows and macOS.

## Quick start with Docker

```sh
cp .env.example .env
openssl rand -base64 48
# Paste the generated value into BALANCE_JWT_SECRET in .env
docker compose up -d --build
curl http://localhost:8080/health
```

Open `http://localhost:8080` to register or sign in to the web application. Data is kept in the `balance-data` Docker volume. Back it up while the container is stopped.

## Run without Docker

Install Go 1.25 or newer, then run:

```sh
go mod tidy
go build -o balance-server ./cmd/balance-server
```

On Linux or macOS:

```sh
export BALANCE_JWT_SECRET="replace-with-a-long-random-secret"
export BALANCE_DB_PATH="./data/balance.db"
./balance-server
```

On Windows PowerShell:

```powershell
$env:BALANCE_JWT_SECRET = "replace-with-a-long-random-secret"
$env:BALANCE_DB_PATH = ".\data\balance.db"
.\balance-server.exe
```

Cross-compile release binaries from any Go installation:

```sh
GOOS=linux GOARCH=amd64 go build -o dist/balance-server-linux-amd64 ./cmd/balance-server
GOOS=darwin GOARCH=arm64 go build -o dist/balance-server-macos-arm64 ./cmd/balance-server
GOOS=windows GOARCH=amd64 go build -o dist/balance-server-windows-amd64.exe ./cmd/balance-server
```

After starting the binary, open `http://localhost:8080` in a browser. The web assets are embedded into the executable, so there is no separate frontend build, Node.js process or static directory to deploy.

## Web application

The responsive web client includes:

- registration, login, automatic session refresh and logout;
- dashboard, current balance and manual balance adjustment;
- adding, editing, deleting, searching and filtering transactions;
- analytics for 1, 3 and 12 months, spending breakdown and savings rate;
- monthly category budgets;
- custom categories with 50 icons, custom emoji and 24 colors;
- light, dark and system themes, plus RUB, EUR, USD and SEK formatting;
- automatic synchronization every 30 seconds and whenever the browser tab becomes active;
- installable PWA shell for desktop and mobile browsers.

The browser session uses `HttpOnly`, `SameSite=Strict` cookies. Native applications continue to use Bearer access tokens and are fully backward compatible. Only display preferences are saved in browser local storage; tokens and financial records are not stored there.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `BALANCE_ADDR` | `:8080` | Listen address |
| `BALANCE_DB_PATH` | `./data/balance.db` | SQLite file path |
| `BALANCE_JWT_SECRET` | required | Random secret of at least 32 characters |
| `BALANCE_ALLOW_REGISTRATION` | `true` | Allows new accounts |
| `BALANCE_ACCESS_TTL` | `15m` | Access-token lifetime |
| `BALANCE_REFRESH_TTL` | `720h` | Refresh-token lifetime |
| `BALANCE_CORS_ORIGINS` | empty | Comma-separated browser origins; native apps do not need CORS |

## HTTPS

Use HTTPS before exposing the server to a network. The Apple applications accept plain HTTP only for `localhost` and `127.0.0.1`; a physical device should connect through an HTTPS reverse proxy such as Caddy, nginx or a private VPN with TLS. Example Caddy configuration:

```caddyfile
balance.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

Then enter `https://balance.example.com` in each application's Settings → Server account.

## API

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Health check |
| `POST` | `/v1/auth/register` | Create account |
| `POST` | `/v1/auth/login` | Sign in |
| `POST` | `/v1/auth/refresh` | Rotate session tokens |
| `POST` | `/v1/auth/logout` | Revoke refresh token |
| `GET` | `/v1/me` | Current account |
| `POST` | `/v1/sync` | Push and pull changes |

The sync endpoint accepts transactions, custom categories and monthly budgets. The server isolates records by account, stores an append-only change cursor, and resolves competing edits with last-write-wins timestamps. Current Apple and Android clients use push-only requests followed by paginated pulls; update the server and applications together.

## Operational notes

- Registration can be disabled after the required accounts have been created.
- Passwords are stored as salted Argon2id hashes. Refresh tokens are stored only as SHA-256 hashes.
- Back up the SQLite database and its `-wal`/`-shm` files together, or stop the server before copying the database.
- Changing `BALANCE_JWT_SECRET` invalidates access tokens. Existing refresh sessions remain valid and will receive new access tokens after refresh.
- The in-process authentication limiter allows 30 authentication requests per IP per minute. Use a reverse proxy for stronger public rate limiting and request logging.

## Документация проекта

- [`AGENTS.md`](AGENTS.md) — правила для AI-агентов и разработчиков.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — архитектура backend.
- [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) — модель данных.
- [`docs/API.md`](docs/API.md) — HTTP API.
- [`docs/SYNC.md`](docs/SYNC.md) — протокол синхронизации.
- [`docs/SECURITY.md`](docs/SECURITY.md) — требования безопасности.
- [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — локальная разработка и проверки.
- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — deployment/production.
- [`docs/PRODUCT.md`](docs/PRODUCT.md) — функциональная роль сервера.

BalanceServer является общим backend для Apple- и Android-клиентов Balance.
