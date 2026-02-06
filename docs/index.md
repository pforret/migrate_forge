# migrate_forge

Migrate a Laravel website from one [Laravel Forge](https://forge.laravel.com)-managed server to another, using a password-protected zip archive as the transport mechanism.

Built with [bashew](https://github.com/pforret/bashew).

## Overview

`migrate_forge` provides four verbs for a complete server migration workflow:

| Verb | Run where | Purpose |
|------|-----------|---------|
| `wizard` | Your machine | Interactive guide: pick servers, sites, and generate a step-by-step plan |
| `backup` | Source server (SSH) | Pack .env, MySQL dump, and `storage/app` into an encrypted zip |
| `restore` | Destination server (SSH) | Unpack the archive, merge .env, restore database and storage |
| `setup` | Any machine | Create the site on the destination Forge server via API |

## Requirements

| Tool | Used by | Install |
|------|---------|---------|
| `bash` 4+ | all | pre-installed on most systems |
| `zip` / `unzip` | backup / restore | `apt install zip unzip` or `brew install zip` |
| `mysqldump` / `mysql` | backup / restore | comes with `mysql-client` |
| `jq` | all | `apt install jq` or `brew install jq` |
| `curl` | setup | pre-installed on most systems |
| `fzf` | wizard | `apt install fzf` or `brew install fzf` |
| `awk` | all | pre-installed |

## Installation

Using [basher](https://github.com/basherpm/basher):

```bash
basher install pforret/migrate_forge
```

Or manually:

```bash
git clone https://github.com/pforret/migrate_forge.git
cd migrate_forge
chmod +x migrate_forge.sh
```

## Configuration

Copy the example env file and fill in your values:

```bash
cp migrate_forge.env.example migrate_forge.env
```

```env
# Required for the 'setup' verb (Forge API)
# Generate at: https://forge.laravel.com/user-profile/api
FORGE_API_TOKEN=

# Forge server IDs (numeric, visible in the Forge dashboard URL)
FORGE_SOURCE_SERVER=
DEST_SERVER=
```

The script auto-loads `.env` files from its own directory and the current working directory (see [Environment files](#environment-files)).

## Usage

```
migrate_forge.sh [-h] [-Q] [-V] [-f] [-d <domain>] [-s <server>]
                 [-D <DEST_SERVER>] [-r <root>] [-o <output>]
                 <action> [<input>]
```

### Flags

| Flag | Long | Description |
|------|------|-------------|
| `-h` | `--help` | Show usage and examples |
| `-Q` | `--QUIET` | Suppress normal output |
| `-V` | `--VERBOSE` | Show debug messages |
| `-f` | `--FORCE` | Skip all confirmation prompts (answer yes) |

### Options

| Option | Long | Description | Default |
|--------|------|-------------|---------|
| `-d` | `--domain` | Website domain name | *(auto-detected from .env)* |
| `-s` | `--server` | Forge source server ID | |
| `-D` | `--DEST_SERVER` | Forge destination server ID | |
| `-r` | `--root` | Laravel project root folder | `.` |
| `-o` | `--output` | Output zip file path | `migrate_<domain>_<date>.zip` |

## Commands

### wizard

Interactive guided migration. Uses `fzf` to let you pick source/destination servers from `~/.ssh/config`, lists sites on each server via SSH, and generates a step-by-step migration plan with exact commands to run.

```bash
./migrate_forge.sh wizard
```

Example session:

```
=== Laravel Forge Migration Wizard ===

Step 1: Select the source server
  > old-forge-server

Step 2: Select the site to migrate
  > example.com

Step 3: What to include in the migration?
  Include database dump? [Y/n] y
  Include storage/app? [Y/n] y

Step 4: Select the destination server
  > new-forge-server

Step 5: Destination site
  > [NEW] Use same domain: example.com

=== Migration Plan ===

Source : old-forge-server -> /home/forge/example.com
Dest   : new-forge-server -> /home/forge/example.com

Step 1: Create backup on source server
  ssh old-forge-server
  migrate_forge.sh backup -d example.com -r /home/forge/example.com

Step 2: Transfer archive to destination
  scp old-forge-server:/home/forge/example.com/migrate_*.zip /tmp/
  scp /tmp/migrate_*.zip new-forge-server:/tmp/

Step 3: Restore on destination server
  ssh new-forge-server
  migrate_forge.sh restore /tmp/migrate_*.zip -r /home/forge/example.com

Step 4: Verify and update DNS
```

### backup

Run **on the source server** via SSH. Creates a password-protected zip archive containing:

- `manifest.json` -- metadata (domain, PHP version, git remote, timestamp, etc.)
- `dotenv` -- the `.env` file
- `database.sql` -- MySQL dump (`--single-transaction --routines --triggers`)
- `storage_app/` -- contents of `storage/app`

```bash
# From the Laravel project directory
./migrate_forge.sh backup -d example.com

# Specify a different project root
./migrate_forge.sh backup -d example.com -r /home/forge/example.com

# Custom output path
./migrate_forge.sh backup -d example.com -o /tmp/my-backup.zip
```

The domain is auto-detected from `APP_URL` in `.env` if not specified with `-d`.

You will be prompted to set a password for the zip archive.

### restore

Run **on the destination server** via SSH. Extracts the archive and restores all components.

```bash
./migrate_forge.sh restore /tmp/migrate_example_com_2026-02-06.zip
```

With a different project root:

```bash
./migrate_forge.sh restore /tmp/migrate_example_com_2026-02-06.zip -r /home/forge/example.com
```

The restore process:

1. Prompts for the zip password
2. Displays archive metadata (domain, database, PHP version, git info)
3. Asks for confirmation before proceeding
4. **Smart .env merge:**
   - Variables only in backup: added to destination
   - Variables only in destination: kept as-is
   - Same value in both: kept as-is
   - Server-dependent vars (`DB_HOST`, `REDIS_HOST`, etc.): destination value kept
   - Other conflicts: prompts you to choose (use `-f` to auto-keep destination values)
5. Restores the MySQL database (with confirmation, since it overwrites)
6. Restores `storage/app` (backs up existing folder first)
7. Fixes permissions (`forge:forge`, `775`)
8. Runs `php artisan config:cache` and `php artisan migrate --force`

### setup

Run **from any machine** with network access to the Forge API. Creates and configures a new site on the destination server, mirroring the source site.

```bash
./migrate_forge.sh setup -d example.com -s 12345 -D 67890
```

Requires `FORGE_API_TOKEN` in your environment or `.env` file.

The setup process:

1. Verifies API access
2. Looks up the source site by domain
3. Creates the site on the destination server (same PHP version, directory)
4. Installs the same git repository and branch
5. Copies the deployment script
6. Triggers an initial deployment
7. Requests a Let's Encrypt SSL certificate

### check

Show current configuration values and verify required commands are available.

```bash
./migrate_forge.sh check
```

## Full Migration Walkthrough

A typical migration from server `old-server` (ID `12345`) to `new-server` (ID `67890`) for `example.com`:

```bash
# 1. (Optional) Create the site on the new server via Forge API
./migrate_forge.sh setup -d example.com -s 12345 -D 67890

# 2. SSH into the source server and create a backup
ssh old-server
cd /home/forge/example.com
/path/to/migrate_forge.sh backup -d example.com
# -> creates migrate_example_com_2026-02-06.zip (password-protected)

# 3. Transfer the archive to the destination server
scp migrate_example_com_2026-02-06.zip new-server:/tmp/

# 4. SSH into the destination server and restore
ssh new-server
cd /home/forge/example.com
/path/to/migrate_forge.sh restore /tmp/migrate_example_com_2026-02-06.zip

# 5. Update DNS records for example.com to point to the new server IP
# 6. Wait for DNS propagation, then verify the site
```

Or use the **wizard** to generate these steps interactively:

```bash
./migrate_forge.sh wizard
```

## Archive Format

The migration archive is a password-protected zip file containing:

```
migrate_example_com_2026-02-06.zip
├── manifest.json      # migration metadata
├── dotenv             # .env file from source
├── database.sql       # MySQL dump
└── storage_app/       # contents of storage/app
```

**manifest.json** example:

```json
{
  "domain": "example.com",
  "created_at": "2026-02-06T14:30:00Z",
  "script_version": "0.0.1",
  "php_version": "8.3",
  "db_connection": "mysql",
  "db_database": "example_db",
  "git_remote": "git@github.com:user/repo.git",
  "git_branch": "main",
  "storage_size_mb": 120,
  "project_root": "/home/forge/example.com"
}
```

## Environment Files

The script automatically loads `.env` files in this order (later files override earlier ones):

1. `<script_folder>/.env`
2. `<script_folder>/.migrate_forge.env`
3. `<script_folder>/migrate_forge.env`
4. `./.env` (current directory, if different from script folder)
5. `./.migrate_forge.env`
6. `./migrate_forge.env`

## Limitations

- **MySQL only** -- PostgreSQL and SQLite are not supported
- Backs up `storage/app` only (not `storage/logs`, `storage/framework/cache`, etc.)
- Forge API v1 (current, deprecated March 2026)
- The `backup` and `restore` verbs must be run directly on the respective servers via SSH
- Large `storage/app` folders may result in slow zip/transfer times

## Author

Peter Forret ([@pforret](https://github.com/pforret)) -- [peter@forret.com](mailto:peter@forret.com)

## License

MIT
