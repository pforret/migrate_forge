#!/usr/bin/env bash
### ==============================================================================
### SO HOW DO YOU PROCEED WITH YOUR SCRIPT?
### 1. define the flags/options/parameters and defaults you need in Option:config()
### 2. implement the different verbs in Script:main() directly or with helper functions do_action1
### 3. implement helper functions you defined in previous step
### ==============================================================================
###
### FOR LLMs: QUICK REFERENCE
### -------------------------
### ADDING NEW VERBS: In Option:config(), add verb to the choice line (e.g., "action1,action2,newverb")
###                   then add a case block in Script:main(): newverb) do_newverb ;;
###
### OPTIONS/FLAGS become variables:
###   flag|f|FORCE|...        => $FORCE (0 or 1)
###   option|o|output|...|x   => $output (default "x")
###   param|1|input|...       => $input (required positional arg)
###
### ENV FILES: Automatically loaded in order (later files override earlier):
###   1. <script_folder>/.env
###   2. <script_folder>/.<script_prefix>.env
###   3. <script_folder>/<script_prefix>.env
###   4. ./.env (current dir, if different from script folder)
###   5. ./.<script_prefix>.env
###   6. ./<script_prefix>.env
###
### Os:require "binary" ["package"] - check if binary exists, die if not
###   Os:require "awk"                      => check for awk, suggest: brew install awk
###   Os:require "convert" "imagemagick"    => check for convert, suggest: brew install imagemagick
###   Os:require "prog" "pip install prog"  => check for prog, suggest: pip install prog
###   With -f/--FORCE flag: auto-installs missing binaries instead of dying
###
### IO FUNCTIONS and effect of --QUIET (-Q) and --VERBOSE (-V):
###   IO:print "msg"   : normal output (stdout)     - hidden by -Q
###   IO:debug "msg"   : debug info (stderr)        - only shown with -V
###   IO:success "msg" : success message (stdout)   - hidden by -Q
###   IO:announce "msg": announcement + 1s pause    - hidden by -Q
###   IO:alert "msg"   : warning message (stderr)   - always shown
###   IO:die "msg"     : error message + exit       - always shown
###   IO:progress "msg": overwriting progress line  - hidden by -Q
###   IO:log "msg"     : append to $log_file        - not affected by -Q/-V
###   IO:confirm "?"   : ask y/N question           - skipped (=yes) with -f/--FORCE
###
### STRING FUNCTIONS:
###   Str:trim "  text  "                => "text" (remove leading/trailing whitespace)
###   Str:lower "HELLO"                  => "hello"
###   Str:upper "hello"                  => "HELLO"
###   Str:ascii "café"                   => "cafe" (remove diacritics)
###   Str:slugify "Hello World!"         => "hello-world" (URL-safe)
###   Str:slugify "Hello World!" "_"     => "hello_world" (custom separator)
###   Str:title "hello world"            => "HelloWorld"
###   Str:title "hello world" "_"        => "Hello_World"
###   Str:digest 8 <<< "text"            => "d3b07384" (MD5 hash, first N chars)
### ==============================================================================

### Created by Peter Forret ( pforret ) on 2026-02-06
### Based on https://github.com/pforret/bashew 1.22.1
script_version="0.0.1" # if there is a VERSION.md in this script's folder, that will have priority over this version number
readonly script_author="peter@forret.com"
readonly script_created="2026-02-06"
readonly run_as_root=-1 # run_as_root: 0 = don't check anything / 1 = script MUST run as root / -1 = script MAY NOT run as root
readonly script_description="Migrate a website from one Laravel Forge managed server to another"

function Option:config() {
  ### SYNTAX: type|short|long|description[|default][|choices]
  ###
  ### flag   => -x or --xxxx sets $xxxx=1 (default: 0)
  ### option => -x <val> or --xxxx <val> sets $xxxx=val
  ### list   => -x <v1> -x <v2> sets ${xxxx[@]} array
  ### param  => positional arg: 1=required, ?=optional, n=multiple
  ### choice => positional arg with validation against allowed values
  ###
  ### Examples:
  ###   flag|v|VERBOSE|show debug info          => $VERBOSE (0/1)
  ###   option|o|output|output file|out.txt     => $output (default: out.txt)
  ###   list|t|tag|add tags                     => ${tag[@]}
  ###   param|1|input|input file                => $input (required)
  ###   param|?|extra|optional arg              => $extra (optional)
  ###   choice|1|action|verb|run,test,build     => $action (validated)
  grep <<<"
#commented lines will be filtered
flag|h|help|show usage
flag|Q|QUIET|no output
flag|V|VERBOSE|also show debug messages
flag|f|FORCE|do not ask for confirmation (always yes)
option|L|LOG_DIR|folder for log files |$HOME/log/$script_prefix
option|T|TMP_DIR|folder for temp files|/tmp/$script_prefix
option|d|domain|website domain name
option|s|server|Forge source server ID
option|D|DEST_SERVER|Forge destination server ID
option|r|root|Laravel project root folder|.
option|o|output|output zip file path
choice|1|action|action to perform|wizard,backup,restore,setup,check,env,update
param|?|input|input file/text
" -v -e '^#' -e '^\s*$'
}

#####################################################################
## Put your Script:main script here
#####################################################################

function Script:main() {
  IO:log "[$script_basename] $script_version started"

  Os:require "awk"

  case "${action,,}" in # ${action,,} = lowercase $action
  wizard)
    #TIP: use «$script_prefix wizard» for interactive guided migration
    #TIP:> $script_prefix wizard
    do_wizard
    ;;

  backup)
    #TIP: use «$script_prefix backup» to create a migration archive of a Laravel site
    #TIP:> $script_prefix backup -d example.com -r /home/forge/example.com
    do_backup
    ;;

  restore)
    #TIP: use «$script_prefix restore» to restore a Laravel site from a migration archive
    #TIP:> $script_prefix restore <archive.zip>
    do_restore
    ;;

  setup)
    #TIP: use «$script_prefix setup» to create a new site on the destination Forge server
    #TIP:> $script_prefix setup -d example.com -s 12345 -D 67890
    do_setup
    ;;

  check | env)
    #TIP: use «$script_prefix check» to check if this script is ready to execute and what values the options/flags are
    #TIP:> $script_prefix check
    #TIP: use «$script_prefix env» to generate an example .env file
    #TIP:> $script_prefix env > .env
    Script:check
    ;;

  update)
    #TIP: use «$script_prefix update» to update to the latest version
    #TIP:> $script_prefix update
    Script:git_pull
    ;;

  *)
    IO:die "action [$action] not recognized"
    ;;
  esac
  IO:log "[$script_basename] ended after $SECONDS secs"
  #TIP: >>> bash script created with «pforret/bashew»
  #TIP: >>> for bash development, also check out «pforret/setver» and «pforret/progressbar»
}

#####################################################################
## Put your helper scripts here
## Available variables: all flags/options from Option:config()
## Useful functions: IO:print, IO:debug, IO:die, IO:success, IO:confirm
##                   Os:require "binary" [install_cmd], Os:tempfile [ext]
#####################################################################

#####################################################################
## .env variables that are server-dependent and should NOT be copied
## during migration (destination server keeps its own values)
#####################################################################
readonly ENV_SERVER_VARS="DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST REDIS_PASSWORD REDIS_PORT MEMCACHED_HOST MAIL_MAILER MAIL_HOST MAIL_PORT MAIL_USERNAME MAIL_PASSWORD QUEUE_CONNECTION SESSION_DRIVER CACHE_DRIVER LOG_CHANNEL APP_URL"

#####################################################################
## Helper: parse a single value from a .env file
#####################################################################
function parse_dotenv() {
  local env_file="$1"
  local key="$2"
  grep "^${key}=" "$env_file" 2>/dev/null | head -1 | cut -d'=' -f2- | sed 's/^["'\''"]//;s/["'\''"]$//'
}

#####################################################################
## Helper: detect Laravel project root (find artisan file)
#####################################################################
function detect_project_root() {
  local start_dir="${1:-.}"
  # resolve to absolute path
  start_dir=$(cd "$start_dir" 2>/dev/null && pwd)
  if [[ -f "${start_dir}/artisan" ]]; then
    echo "$start_dir"
    return 0
  fi
  IO:die "No Laravel project found at [${start_dir}] (no artisan file)"
}

#####################################################################
## Helper: Forge API wrapper
#####################################################################
function forge_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  local api_token="${FORGE_API_TOKEN:-}"
  [[ -z "${api_token}" ]] && IO:die "FORGE_API_TOKEN not set"

  local url="https://forge.laravel.com/api/v1${endpoint}"
  IO:debug "API ${method} ${url}"

  local response
  if [[ -n "${data}" ]]; then
    response=$(curl --silent --show-error --fail \
      -X "${method}" \
      -H "Authorization: Bearer ${api_token}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "${data}" \
      "${url}" 2>&1) || IO:die "Forge API error: ${response}"
  else
    response=$(curl --silent --show-error --fail \
      -X "${method}" \
      -H "Authorization: Bearer ${api_token}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      "${url}" 2>&1) || IO:die "Forge API error: ${response}"
  fi
  echo "${response}"
}

#####################################################################
## Helper: dump MySQL database
#####################################################################
function dump_mysql() {
  local db_host="$1"
  local db_port="$2"
  local db_name="$3"
  local db_user="$4"
  local db_pass="$5"
  local output_file="$6"

  Os:require "mysqldump"
  IO:debug "Dumping MySQL database [${db_name}] from [${db_host}:${db_port}]"
  MYSQL_PWD="${db_pass}" mysqldump \
    --host="${db_host}" \
    --port="${db_port}" \
    --user="${db_user}" \
    --single-transaction \
    --routines \
    --triggers \
    --quick \
    "${db_name}" > "${output_file}" \
    || IO:die "mysqldump failed for database [${db_name}]"
  local size
  size=$(du -h "${output_file}" | cut -f1)
  IO:debug "Database dump: ${size}"
}

#####################################################################
## Helper: restore MySQL database
#####################################################################
function restore_mysql() {
  local db_host="$1"
  local db_port="$2"
  local db_name="$3"
  local db_user="$4"
  local db_pass="$5"
  local input_file="$6"

  Os:require "mysql"
  IO:debug "Restoring MySQL database [${db_name}] on [${db_host}:${db_port}]"
  MYSQL_PWD="${db_pass}" mysql \
    --host="${db_host}" \
    --port="${db_port}" \
    --user="${db_user}" \
    "${db_name}" < "${input_file}" \
    || IO:die "MySQL restore failed for database [${db_name}]"
}

#####################################################################
## Helper: create manifest.json
#####################################################################
function create_manifest() {
  local manifest_file="$1"
  local site_domain="$2"
  local db_name="$3"
  local project_root="$4"

  Os:require "jq"
  local git_remote_url=""
  local git_branch=""
  if [[ -d "${project_root}/.git" ]]; then
    git_remote_url=$(git -C "${project_root}" remote get-url origin 2>/dev/null || echo "")
    git_branch=$(git -C "${project_root}" branch --show-current 2>/dev/null || echo "")
  fi

  local php_ver=""
  php_ver=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;' 2>/dev/null || echo "unknown")

  local storage_size="0"
  if [[ -d "${project_root}/storage/app" ]]; then
    storage_size=$(du -sm "${project_root}/storage/app" 2>/dev/null | cut -f1)
  fi

  jq -n \
    --arg domain "${site_domain}" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg script_version "${script_version}" \
    --arg php_version "${php_ver}" \
    --arg db_connection "mysql" \
    --arg db_database "${db_name}" \
    --arg git_remote "${git_remote_url}" \
    --arg git_branch "${git_branch}" \
    --arg storage_size_mb "${storage_size}" \
    --arg project_root "${project_root}" \
    '{
      domain: $domain,
      created_at: $created_at,
      script_version: $script_version,
      php_version: $php_version,
      db_connection: $db_connection,
      db_database: $db_database,
      git_remote: $git_remote,
      git_branch: $git_branch,
      storage_size_mb: ($storage_size_mb | tonumber),
      project_root: $project_root
    }' > "${manifest_file}"
}

#####################################################################
## Helper: read manifest.json into global variables
#####################################################################
function read_manifest() {
  local manifest_file="$1"
  Os:require "jq"
  [[ ! -f "${manifest_file}" ]] && IO:die "Manifest not found: [${manifest_file}]"

  manifest_domain=$(jq -r '.domain' "${manifest_file}")
  manifest_created_at=$(jq -r '.created_at' "${manifest_file}")
  manifest_db_connection=$(jq -r '.db_connection' "${manifest_file}")
  manifest_db_database=$(jq -r '.db_database' "${manifest_file}")
  manifest_git_remote=$(jq -r '.git_remote' "${manifest_file}")
  manifest_git_branch=$(jq -r '.git_branch' "${manifest_file}")
  manifest_storage_size_mb=$(jq -r '.storage_size_mb' "${manifest_file}")
  manifest_php_version=$(jq -r '.php_version' "${manifest_file}")
}

#####################################################################
## Helper: smart .env merge
## - only in backup: add to result
## - only in current: keep in result
## - same value: keep in result
## - different value: prompt user, default = current value
#####################################################################
function merge_env() {
  local backup_env="$1"
  local current_env="$2"
  local output_env="$3"

  IO:announce "Merging .env files..."

  # collect all unique keys from both files (skip comments and empty lines)
  local all_keys
  all_keys=$(cat "${backup_env}" "${current_env}" 2>/dev/null \
    | grep -v '^#' | grep -v '^\s*$' | grep '=' \
    | cut -d'=' -f1 | sort -u)

  local key backup_val current_val
  true > "${output_env}" # start with empty file

  for key in ${all_keys}; do
    backup_val=$(parse_dotenv "${backup_env}" "${key}")
    current_val=$(parse_dotenv "${current_env}" "${key}")

    if [[ -z "${current_val}" && -n "${backup_val}" ]]; then
      # only in backup: add it
      IO:debug "  + ${key} (from backup)"
      echo "${key}=${backup_val}" >> "${output_env}"

    elif [[ -n "${current_val}" && -z "${backup_val}" ]]; then
      # only in current: keep it
      IO:debug "  = ${key} (kept from current)"
      echo "${key}=${current_val}" >> "${output_env}"

    elif [[ "${backup_val}" == "${current_val}" ]]; then
      # same value: keep it
      echo "${key}=${current_val}" >> "${output_env}"

    else
      # different value: check if server-dependent
      if echo " ${ENV_SERVER_VARS} " | grep -q " ${key} "; then
        # server-dependent var: keep current by default
        IO:debug "  = ${key} (server-dependent, kept current)"
        echo "${key}=${current_val}" >> "${output_env}"
      elif ((FORCE)); then
        # --force: keep current value
        echo "${key}=${current_val}" >> "${output_env}"
      else
        # ask user
        IO:print ""
        IO:print "${txtWarn}Conflict for ${key}:${txtReset}"
        IO:print "  backup : ${backup_val}"
        IO:print "  current: ${current_val}"
        local answer
        answer=$(IO:question "Keep which? [c]urrent / [b]ackup" "c")
        case "${answer}" in
          b|B|backup)
            echo "${key}=${backup_val}" >> "${output_env}"
            ;;
          *)
            echo "${key}=${current_val}" >> "${output_env}"
            ;;
        esac
      fi
    fi
  done
  IO:success ".env merge complete"
}

#####################################################################
## Helper: parse SSH config for host list
#####################################################################
function list_ssh_hosts() {
  local ssh_config="${HOME}/.ssh/config"
  [[ ! -f "${ssh_config}" ]] && IO:die "No SSH config found at [${ssh_config}]"
  grep -i "^Host " "${ssh_config}" | awk '{print $2}' | grep -v '[*?]' | sort
}

#####################################################################
## Helper: pick from a list using fzf
## Usage: pick_from_list "prompt" item1 item2 item3 ...
## Returns the chosen item on stdout
#####################################################################
function pick_from_list() {
  local prompt="$1"
  shift
  local items=("$@")

  local choice
  choice=$(printf '%s\n' "${items[@]}" | fzf --height=~50% --layout=reverse --prompt="${prompt} > ") \
    || IO:die "No selection made"
  [[ -z "${choice}" ]] && IO:die "No selection made"
  echo "${choice}"
}

#####################################################################
## Helper: list sites on a remote Forge server via SSH
#####################################################################
function list_remote_sites() {
  local ssh_host="$1"
  IO:debug "Listing sites on [${ssh_host}]"
  ssh -o ConnectTimeout=5 "${ssh_host}" "ls -1 /home/forge/ 2>/dev/null | grep -v '^\\.'" 2>/dev/null \
    || IO:die "Cannot SSH to [${ssh_host}] or no sites found"
}

#####################################################################
## VERB: backup - create a migration archive from a Laravel site
#####################################################################
function do_backup() {
  Os:require "zip"
  Os:require "mysqldump"
  Os:require "jq"

  # 1. Find Laravel root
  local project_root
  # shellcheck disable=SC2154
  project_root=$(detect_project_root "${root}") # $root set by Option:parse
  IO:debug "Project root: ${project_root}"

  # 2. Parse .env
  local env_file="${project_root}/.env"
  [[ ! -f "${env_file}" ]] && IO:die "No .env file found at [${env_file}]"

  local db_connection db_host db_port db_name db_user db_pass
  db_connection=$(parse_dotenv "${env_file}" "DB_CONNECTION")
  db_host=$(parse_dotenv "${env_file}" "DB_HOST")
  db_port=$(parse_dotenv "${env_file}" "DB_PORT")
  db_name=$(parse_dotenv "${env_file}" "DB_DATABASE")
  db_user=$(parse_dotenv "${env_file}" "DB_USERNAME")
  db_pass=$(parse_dotenv "${env_file}" "DB_PASSWORD")

  [[ "${db_connection}" != "mysql" ]] && IO:die "Only MySQL is supported (found DB_CONNECTION=${db_connection})"
  [[ -z "${db_name}" ]] && IO:die "DB_DATABASE not set in .env"

  # 3. Determine domain
  if [[ -z "${domain}" ]]; then
    domain=$(parse_dotenv "${env_file}" "APP_URL" | sed 's|https\?://||;s|/.*||')
  fi
  [[ -z "${domain}" ]] && IO:die "Could not determine domain - use -d <domain>"
  IO:print "Backing up site: ${txtBold}${domain}${txtReset}"

  # 4. Create temp working dir
  local work_dir
  work_dir="${TMP_DIR}/backup_$$"
  mkdir -p "${work_dir}"

  # 5. Dump database
  IO:announce "Dumping MySQL database [${db_name}]..."
  dump_mysql "${db_host}" "${db_port:-3306}" "${db_name}" "${db_user}" "${db_pass}" "${work_dir}/database.sql"

  # 6. Copy .env
  IO:announce "Copying .env file..."
  cp "${env_file}" "${work_dir}/dotenv"

  # 7. Copy storage/app
  if [[ -d "${project_root}/storage/app" ]]; then
    local storage_size
    storage_size=$(du -sm "${project_root}/storage/app" 2>/dev/null | cut -f1)
    IO:announce "Copying storage/app (${storage_size} MB)..."
    mkdir -p "${work_dir}/storage_app"
    cp -r "${project_root}/storage/app/." "${work_dir}/storage_app/"
  else
    IO:debug "No storage/app folder found, skipping"
  fi

  # 8. Create manifest
  IO:announce "Creating manifest..."
  create_manifest "${work_dir}/manifest.json" "${domain}" "${db_name}" "${project_root}"

  # 9. Create password-protected zip
  local slug
  slug="${domain//[^a-zA-Z0-9]/_}"
  local zip_name
  zip_name="${output:-migrate_${slug}_$(date +%Y-%m-%d).zip}"
  # resolve to absolute path if relative
  [[ "${zip_name}" != /* ]] && zip_name="$(pwd)/${zip_name}"

  IO:announce "Creating encrypted zip archive..."
  IO:print "You will be prompted to set a password for the archive."
  (cd "${work_dir}" && zip -r -e "${zip_name}" manifest.json dotenv database.sql storage_app/ 2>/dev/null) \
    || IO:die "Failed to create zip archive"

  # 10. Report
  local size
  size=$(du -h "${zip_name}" | cut -f1)
  IO:success "Backup created: ${zip_name} (${size})"
  IO:print ""
  IO:print "Next steps:"
  IO:print "  1. Transfer to destination server: scp ${zip_name} dest-server:/tmp/"
  IO:print "  2. On destination server, run: $script_prefix restore /tmp/$(basename "${zip_name}")"

  # 11. Cleanup
  rm -rf "${work_dir}"
}

#####################################################################
## VERB: restore - restore a Laravel site from a migration archive
#####################################################################
function do_restore() {
  Os:require "unzip"
  Os:require "mysql"
  Os:require "jq"

  local zip_file="${input}"
  [[ -z "${zip_file}" ]] && IO:die "Usage: $script_prefix restore <archive.zip>"
  [[ ! -f "${zip_file}" ]] && IO:die "File not found: [${zip_file}]"

  # 1. Extract (will prompt for password)
  local work_dir
  work_dir="${TMP_DIR}/restore_$$"
  mkdir -p "${work_dir}"
  IO:announce "Extracting archive (enter password when prompted)..."
  unzip "${zip_file}" -d "${work_dir}" || IO:die "Failed to extract - wrong password?"

  # 2. Read manifest
  [[ ! -f "${work_dir}/manifest.json" ]] && IO:die "Invalid archive - no manifest.json found"
  read_manifest "${work_dir}/manifest.json"
  IO:print ""
  IO:print "Migration archive info:"
  IO:print "  Domain    : ${txtBold}${manifest_domain}${txtReset}"
  IO:print "  Created   : ${manifest_created_at}"
  IO:print "  Database  : ${manifest_db_connection} / ${manifest_db_database}"
  IO:print "  PHP       : ${manifest_php_version}"
  IO:print "  Git       : ${manifest_git_remote} (${manifest_git_branch})"
  IO:print "  Storage   : ${manifest_storage_size_mb} MB"
  IO:print ""

  # 3. Confirm
  IO:confirm "Proceed with restore?" || IO:die "Aborted by user"

  # 4. Detect project root
  local project_root
  # shellcheck disable=SC2154
  project_root=$(detect_project_root "${root}") # $root set by Option:parse
  IO:print "Restoring to: ${project_root}"

  # 5. Smart .env merge
  if [[ -f "${work_dir}/dotenv" ]]; then
    if [[ -f "${project_root}/.env" ]]; then
      IO:announce "Merging .env files..."
      local backup_ts
      backup_ts=$(date +%Y%m%d%H%M%S)
      cp "${project_root}/.env" "${project_root}/.env.pre-migrate.${backup_ts}"
      IO:debug "Existing .env backed up to .env.pre-migrate.${backup_ts}"
      merge_env "${work_dir}/dotenv" "${project_root}/.env" "${project_root}/.env.new"
      mv "${project_root}/.env.new" "${project_root}/.env"
    else
      IO:announce "No existing .env - copying from backup..."
      cp "${work_dir}/dotenv" "${project_root}/.env"
      IO:alert "IMPORTANT: Update server-dependent vars in .env (DB_HOST, REDIS_HOST, etc.)"
    fi
  fi

  # 6. Restore database
  if [[ -f "${work_dir}/database.sql" ]]; then
    local db_host db_port db_name db_user db_pass
    db_host=$(parse_dotenv "${project_root}/.env" "DB_HOST")
    db_port=$(parse_dotenv "${project_root}/.env" "DB_PORT")
    db_name=$(parse_dotenv "${project_root}/.env" "DB_DATABASE")
    db_user=$(parse_dotenv "${project_root}/.env" "DB_USERNAME")
    db_pass=$(parse_dotenv "${project_root}/.env" "DB_PASSWORD")
    [[ -z "${db_name}" ]] && IO:die "DB_DATABASE not set in .env - cannot restore database"

    IO:announce "Restoring MySQL database [${db_name}]..."
    IO:confirm "This will overwrite database [${db_name}]. Continue?" || IO:die "Aborted"
    restore_mysql "${db_host}" "${db_port:-3306}" "${db_name}" "${db_user}" "${db_pass}" "${work_dir}/database.sql"
    IO:success "Database restored"
  else
    IO:alert "No database dump in archive, skipping"
  fi

  # 7. Restore storage/app
  if [[ -d "${work_dir}/storage_app" ]]; then
    IO:announce "Restoring storage/app..."
    if [[ -d "${project_root}/storage/app" ]]; then
      local backup_ts
      backup_ts=$(date +%Y%m%d%H%M%S)
      mv "${project_root}/storage/app" "${project_root}/storage/app.pre-migrate.${backup_ts}"
      IO:debug "Existing storage/app backed up"
    fi
    mkdir -p "${project_root}/storage/app"
    cp -r "${work_dir}/storage_app/." "${project_root}/storage/app/"
    IO:success "storage/app restored"
  else
    IO:debug "No storage_app in archive, skipping"
  fi

  # 8. Fix permissions
  IO:announce "Fixing permissions..."
  chown -R forge:forge "${project_root}/storage" "${project_root}/bootstrap/cache" 2>/dev/null || true
  chmod -R 775 "${project_root}/storage" "${project_root}/bootstrap/cache" 2>/dev/null || true

  # 9. Laravel cache + migrate
  IO:announce "Running artisan commands..."
  (cd "${project_root}" && php artisan config:cache 2>/dev/null) || IO:alert "config:cache failed (non-fatal)"
  (cd "${project_root}" && php artisan migrate --force 2>/dev/null) || IO:alert "migrate failed - check manually"

  # 10. Cleanup
  rm -rf "${work_dir}"
  IO:success "Restore complete for ${manifest_domain}"
}

#####################################################################
## VERB: setup - create a new site on destination Forge server via API
#####################################################################
function do_setup() {
  Os:require "curl"
  Os:require "jq"

  local api_token="${FORGE_API_TOKEN:-}"
  [[ -z "${api_token}" ]] && IO:die "FORGE_API_TOKEN not set - add to .env or export"

  local source_server="${server:-}"
  local dest_server="${DEST_SERVER:-}"
  [[ -z "${source_server}" ]] && IO:die "Source server ID not set - use -s <server_id>"
  [[ -z "${dest_server}" ]] && IO:die "Destination server ID not set - use -D <server_id>"
  [[ -z "${domain}" ]] && IO:die "Domain not set - use -d <domain>"

  # 1. Test API access
  IO:announce "Verifying Forge API access..."
  forge_api GET "/servers" > /dev/null

  # 2. Find source site by domain
  IO:announce "Looking up site [${domain}] on server [${source_server}]..."
  local sites_json source_site_id
  sites_json=$(forge_api GET "/servers/${source_server}/sites")
  source_site_id=$(echo "${sites_json}" | jq -r ".sites[] | select(.name == \"${domain}\") | .id")
  [[ -z "${source_site_id}" ]] && IO:die "Site [${domain}] not found on server [${source_server}]"
  IO:debug "Source site ID: ${source_site_id}"

  # 3. Get source site details
  local site_json
  site_json=$(forge_api GET "/servers/${source_server}/sites/${source_site_id}")
  local repository branch php_version directory
  repository=$(echo "${site_json}" | jq -r '.site.repository // empty')
  branch=$(echo "${site_json}" | jq -r '.site.repository_branch // "main"')
  php_version=$(echo "${site_json}" | jq -r '.site.php_version // "php83"')
  directory=$(echo "${site_json}" | jq -r '.site.directory // "/public"')

  IO:print "Source site details:"
  IO:print "  Repository: ${repository}"
  IO:print "  Branch    : ${branch}"
  IO:print "  PHP       : ${php_version}"
  IO:print "  Directory : ${directory}"

  # 4. Get source deployment script
  IO:announce "Getting deployment script..."
  local deploy_script
  deploy_script=$(forge_api GET "/servers/${source_server}/sites/${source_site_id}/deployment/script")

  # 5. Create site on destination
  IO:announce "Creating site [${domain}] on server [${dest_server}]..."
  local create_payload new_site new_site_id
  create_payload=$(jq -n \
    --arg domain "${domain}" \
    --arg directory "${directory}" \
    --arg php_version "${php_version}" \
    '{ domain: $domain, project_type: "php", directory: $directory, php_version: $php_version }')
  new_site=$(forge_api POST "/servers/${dest_server}/sites" "${create_payload}")
  new_site_id=$(echo "${new_site}" | jq -r '.site.id')
  [[ -z "${new_site_id}" || "${new_site_id}" == "null" ]] && IO:die "Failed to create site"
  IO:success "Site created with ID: ${new_site_id}"

  # 6. Install git repository
  if [[ -n "${repository}" ]]; then
    IO:announce "Installing repository [${repository}] branch [${branch}]..."
    sleep 2 # give Forge a moment to provision the site
    local git_payload
    git_payload=$(jq -n \
      --arg provider "github" \
      --arg repository "${repository}" \
      --arg branch "${branch}" \
      '{ provider: $provider, repository: $repository, branch: $branch, composer: true }')
    forge_api POST "/servers/${dest_server}/sites/${new_site_id}/git" "${git_payload}" > /dev/null
    IO:success "Repository installed"
  fi

  # 7. Update deployment script
  IO:announce "Updating deployment script..."
  sleep 2
  local script_payload
  script_payload=$(jq -n --arg content "${deploy_script}" '{ content: $content }')
  forge_api PUT "/servers/${dest_server}/sites/${new_site_id}/deployment/script" "${script_payload}" > /dev/null
  IO:success "Deployment script updated"

  # 8. Deploy
  IO:announce "Triggering deployment..."
  forge_api POST "/servers/${dest_server}/sites/${new_site_id}/deployment/deploy" "" > /dev/null || true
  IO:success "Deployment triggered"

  # 9. Request SSL
  IO:announce "Requesting Let's Encrypt SSL certificate..."
  local ssl_payload
  ssl_payload=$(jq -n --arg domain "${domain}" '{ domains: [$domain] }')
  forge_api POST "/servers/${dest_server}/sites/${new_site_id}/certificates/letsencrypt" "${ssl_payload}" > /dev/null || IO:alert "SSL request failed - DNS may not point to new server yet"

  IO:success "Site setup complete on server [${dest_server}]"
  IO:print ""
  IO:print "Next steps:"
  IO:print "  1. Run backup on source server: $script_prefix backup -d ${domain} -r /home/forge/${domain}"
  IO:print "  2. Transfer zip: scp migrate_*.zip dest-server:/tmp/"
  IO:print "  3. Restore on dest server: $script_prefix restore /tmp/migrate_*.zip -r /home/forge/${domain}"
  IO:print "  4. Update DNS to point ${domain} to the new server IP"
}

#####################################################################
## VERB: wizard - interactive guided migration
#####################################################################
function do_wizard() {
  Os:require "fzf"

  IO:print "${txtBold}=== Laravel Forge Migration Wizard ===${txtReset}"
  IO:print ""

  # 1. Pick source server from SSH config
  local ssh_hosts
  ssh_hosts=$(list_ssh_hosts)
  [[ -z "${ssh_hosts}" ]] && IO:die "No hosts found in ~/.ssh/config"

  local -a host_array
  # shellcheck disable=SC2206
  IFS=$'\n' host_array=(${ssh_hosts})
  IFS=$'\n\t'

  IO:print "Step 1: Select the ${txtBold}source${txtReset} server"
  local source_host
  source_host=$(pick_from_list "Available SSH hosts:" "${host_array[@]}")
  IO:success "Source server: ${source_host}"

  # 2. List sites on source server
  IO:announce "Connecting to ${source_host} to list sites..."
  local remote_sites
  remote_sites=$(list_remote_sites "${source_host}")
  [[ -z "${remote_sites}" ]] && IO:die "No sites found on [${source_host}]"

  local -a site_array
  # shellcheck disable=SC2206
  IFS=$'\n' site_array=(${remote_sites})
  IFS=$'\n\t'

  IO:print ""
  IO:print "Step 2: Select the ${txtBold}site${txtReset} to migrate"
  local source_site
  source_site=$(pick_from_list "Sites on ${source_host}:" "${site_array[@]}")
  IO:success "Source site: ${source_site}"

  # 3. Ask what to include
  IO:print ""
  IO:print "Step 3: What to include in the migration?"
  local include_db="y"
  local include_storage="y"
  if ! ((FORCE)); then
    read -r -p "Include database dump? [Y/n] " include_db
    [[ -z "${include_db}" ]] && include_db="y"
    read -r -p "Include storage/app? [Y/n] " include_storage
    [[ -z "${include_storage}" ]] && include_storage="y"
  fi

  # 4. Pick destination server
  IO:print ""
  IO:print "Step 4: Select the ${txtBold}destination${txtReset} server"
  local dest_host
  dest_host=$(pick_from_list "Available SSH hosts:" "${host_array[@]}")
  IO:success "Destination server: ${dest_host}"

  # 5. Ask for destination site (existing or new)
  IO:print ""
  IO:print "Step 5: Destination site"
  local dest_site
  IO:announce "Connecting to ${dest_host} to list existing sites..."
  local dest_remote_sites
  dest_remote_sites=$(list_remote_sites "${dest_host}" 2>/dev/null || echo "")

  if [[ -n "${dest_remote_sites}" ]]; then
    local -a dest_site_array
    # shellcheck disable=SC2206
    IFS=$'\n' dest_site_array=(${dest_remote_sites} "[NEW] Use same domain: ${source_site}")
    IFS=$'\n\t'
    dest_site=$(pick_from_list "Sites on ${dest_host} (or create new):" "${dest_site_array[@]}")
    if [[ "${dest_site}" == "[NEW]"* ]]; then
      dest_site="${source_site}"
    fi
  else
    dest_site="${source_site}"
    IO:print "  No existing sites found, will use: ${dest_site}"
  fi
  IO:success "Destination site: ${dest_site}"

  # 6. Generate the migration plan
  IO:print ""
  IO:print "${txtBold}=== Migration Plan ===${txtReset}"
  IO:print ""
  IO:print "Source : ${txtInfo}${source_host}${txtReset} -> /home/forge/${source_site}"
  IO:print "Dest   : ${txtInfo}${dest_host}${txtReset} -> /home/forge/${dest_site}"
  IO:print "Include: database=${include_db}, storage/app=${include_storage}"
  IO:print ""

  local step=1
  local script_path
  script_path=$(Os:follow_link "${BASH_SOURCE[0]}")

  IO:print "${txtBold}Step ${step}: Create backup on source server${txtReset}"
  IO:print "  ssh ${source_host}"
  IO:print "  ${script_path} backup -d ${source_site} -r /home/forge/${source_site}"
  IO:print ""
  ((step++))

  IO:print "${txtBold}Step ${step}: Transfer archive to destination${txtReset}"
  IO:print "  scp ${source_host}:/home/forge/${source_site}/migrate_*.zip /tmp/"
  IO:print "  scp /tmp/migrate_*.zip ${dest_host}:/tmp/"
  IO:print ""
  ((step++))

  if [[ "${source_host}" != "${dest_host}" || "${source_site}" != "${dest_site}" ]]; then
    IO:print "${txtBold}Step ${step}: (Optional) Setup new site via Forge API${txtReset}"
    IO:print "  ${script_path} setup -d ${source_site} -s <source_server_id> -D <dest_server_id>"
    IO:print "  (requires FORGE_API_TOKEN in .env)"
    IO:print ""
    ((step++))
  fi

  IO:print "${txtBold}Step ${step}: Restore on destination server${txtReset}"
  IO:print "  ssh ${dest_host}"
  IO:print "  ${script_path} restore /tmp/migrate_*.zip -r /home/forge/${dest_site}"
  IO:print ""
  ((step++))

  IO:print "${txtBold}Step ${step}: Verify and update DNS${txtReset}"
  IO:print "  - Review .env on destination (especially DB credentials)"
  IO:print "  - Test the site on the new server"
  IO:print "  - Update DNS records for ${source_site} to point to ${dest_host}"
  IO:print "  - Wait for DNS propagation"
  IO:print "  - Request SSL certificate if not done in setup step"
  IO:print ""

  IO:success "Migration plan generated. Follow the steps above in order."
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################
#####################################################################

action=""
error_prefix=""
git_repo_remote=""
git_repo_root=""
install_package=""
os_kernel=""
os_machine=""
os_name=""
os_version=""
script_basename=""
script_hash="?"
script_lines="?"
script_prefix=""
shell_brand=""
shell_version=""
temp_files=()

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
# removed -e because it made basic [[ testing ]] difficult
set -uo pipefail
IFS=$'\n\t'
FORCE=0
help=0

#to enable VERBOSE even before option parsing
VERBOSE=0
[[ $# -gt 0 ]] && [[ $1 == "-v" ]] && VERBOSE=1

#to enable QUIET even before option parsing
QUIET=0
[[ $# -gt 0 ]] && [[ $1 == "-q" ]] && QUIET=1

txtReset=""
txtError=""
txtInfo=""
txtInfo=""
txtWarn=""
txtBold=""
txtItalic=""
txtUnderline=""

char_succes="OK "
char_fail="!! "
char_alert="?? "
char_wait="..."
info_icon="(i)"
config_icon="[c]"
clean_icon="[c]"
require_icon="[r]"

### stdIO:print/stderr output
function IO:initialize() {
  script_started_at="$(Tool:time)"
  IO:debug "script $script_basename started at $script_started_at"

  [[ "${BASH_SOURCE[0]:-}" != "${0}" ]] && sourced=1 || sourced=0
  [[ -t 1 ]] && piped=0 || piped=1 # detect if output is piped
  if [[ $piped -eq 0 && -n "$TERM" ]]; then
    txtReset=$(tput sgr0)
    txtError=$(tput setaf 160)
    txtInfo=$(tput setaf 2)
    txtWarn=$(tput setaf 214)
    txtBold=$(tput bold)
    txtItalic=$(tput sitm)
    txtUnderline=$(tput smul)
  fi

  [[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported
  if [[ $unicode -gt 0 ]]; then
    char_succes="✅"
    char_fail="⛔"
    char_alert="✴️"
    char_wait="⏳"
    info_icon="🌼"
    config_icon="🌱"
    clean_icon="🧽"
    require_icon="🔌"
  fi
  error_prefix="${txtError}>${txtReset}"
}

function IO:print() {
  ((QUIET)) && true || printf '%b\n' "$*"
}

function IO:debug() {
  ((VERBOSE)) && IO:print "${txtInfo}# $* ${txtReset}" >&2
  true
}

function IO:die() {
  IO:print "${txtError}${char_fail} $script_basename${txtReset}: $*" >&2
  Os:beep
  Script:exit
}

function IO:alert() {
  IO:print "${txtWarn}${char_alert}${txtReset}: ${txtUnderline}$*${txtReset}" >&2
}

function IO:success() {
  IO:print "${txtInfo}${char_succes}${txtReset}  ${txtBold}$*${txtReset}"
}

function IO:announce() {
  IO:print "${txtInfo}${char_wait}${txtReset}  ${txtItalic}$*${txtReset}"
  sleep 1
}

function IO:progress() {
  ((QUIET)) || (
    local screen_width
    screen_width=$(tput cols 2>/dev/null || echo 80)
    local rest_of_line
    rest_of_line=$((screen_width - 5))

    if ((piped)); then
      IO:print "... $*" >&2
    else
      printf "... %-${rest_of_line}b\r" "$*                                             " >&2
    fi
  )
}

function IO:countdown() {
  local seconds=${1:-5}
  local message=${2:-Countdown :}
  local i

  if ((piped)); then
    IO:print "$message $seconds seconds"
  else
    for ((i = 0; i < "$seconds"; i++)); do
      IO:progress "${txtInfo}$message $((seconds - i)) seconds${txtReset}"
      sleep 1
    done
    IO:print "                         "
  fi
}

### interactive
function IO:confirm() {
  ((FORCE)) && return 0
  read -r -p "$1 [y/N] " -n 1
  echo " "
  [[ $REPLY =~ ^[Yy]$ ]]
}

function IO:question() {
  local ANSWER
  local DEFAULT=${2:-}
  read -r -p "$1 ($DEFAULT) > " ANSWER
  [[ -z "$ANSWER" ]] && echo "$DEFAULT" || echo "$ANSWER"
}

function IO:log() {
  [[ -n "${log_file:-}" ]] && echo "$(date '+%H:%M:%S') | $*" >>"$log_file"
}

function Tool:calc() {
  awk "BEGIN {print $*} ; "
}

function Tool:round() {
  local number="${1}"
  local decimals="${2:-0}"

  awk "BEGIN {print sprintf( \"%.${decimals}f\" , $number )};"
}

function Tool:time() {
  if [[ $(command -v perl) ]]; then
    perl -MTime::HiRes=time -e 'printf "%f\n", time'
  elif [[ $(command -v php) ]]; then
    php -r 'printf("%f\n",microtime(true));'
  elif [[ $(command -v python) ]]; then
    python -c 'import time; print(time.time()) '
  elif [[ $(command -v python3) ]]; then
    python3 -c 'import time; print(time.time()) '
  elif [[ $(command -v node) ]]; then
    node -e 'console.log(+new Date() / 1000)'
  elif [[ $(command -v ruby) ]]; then
    ruby -e 'STDOUT.puts(Time.now.to_f)'
  else
    date '+%s.000'
  fi
}

function Tool:throughput() {
  local time_started="$1"
  [[ -z "$time_started" ]] && time_started="$script_started_at"
  local operations="${2:-1}"
  local name="${3:-operation}"

  local time_finished
  local duration
  local seconds
  time_finished="$(Tool:time)"
  duration="$(Tool:calc "$time_finished - $time_started")"
  seconds="$(Tool:round "$duration")"
  local ops
  if [[ "$operations" -gt 1 ]]; then
    if [[ $operations -gt $seconds ]]; then
      ops=$(Tool:calc "$operations / $duration")
      ops=$(Tool:round "$ops" 3)
      duration=$(Tool:round "$duration" 2)
      IO:print "$operations $name finished in $duration secs: $ops $name/sec"
    else
      ops=$(Tool:calc "$duration / $operations")
      ops=$(Tool:round "$ops" 3)
      duration=$(Tool:round "$duration" 2)
      IO:print "$operations $name finished in $duration secs: $ops sec/$name"
    fi
  else
    duration=$(Tool:round "$duration" 2)
    IO:print "$name finished in $duration secs"
  fi
}

### string processing

function Str:trim() {
  local var="$*"
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

function Str:lower() {
  if [[ -n "$1" ]]; then
    local input="$*"
    echo "${input,,}"
  else
    awk '{print tolower($0)}'
  fi
}

function Str:upper() {
  if [[ -n "$1" ]]; then
    local input="$*"
    echo "${input^^}"
  else
    awk '{print toupper($0)}'
  fi
}

function Str:ascii() {
  # remove all characters with accents/diacritics to latin alphabet
  # shellcheck disable=SC2020
  sed 'y/àáâäæãåāǎçćčèéêëēėęěîïííīįìǐłñńôöòóœøōǒõßśšûüǔùǖǘǚǜúūÿžźżÀÁÂÄÆÃÅĀǍÇĆČÈÉÊËĒĖĘĚÎÏÍÍĪĮÌǏŁÑŃÔÖÒÓŒØŌǑÕẞŚŠÛÜǓÙǕǗǙǛÚŪŸŽŹŻ/aaaaaaaaaccceeeeeeeeiiiiiiiilnnooooooooosssuuuuuuuuuuyzzzAAAAAAAAACCCEEEEEEEEIIIIIIIILNNOOOOOOOOOSSSUUUUUUUUUUYZZZ/'
}

function Str:slugify() {
  # Str:slugify <input> <separator>
  # Str:slugify "Jack, Jill & Clémence LTD"      => jack-jill-clemence-ltd
  # Str:slugify "Jack, Jill & Clémence LTD" "_"  => jack_jill_clemence_ltd
  separator="${2:-}"
  [[ -z "$separator" ]] && separator="-"
  Str:lower "$1" |
    Str:ascii |
    awk '{
          gsub(/[\[\]@#$%^&*;,.:()<>!?\/+=_]/," ",$0);
          gsub(/^  */,"",$0);
          gsub(/  *$/,"",$0);
          gsub(/  */,"-",$0);
          gsub(/[^a-z0-9\-]/,"");
          print;
          }' |
    sed "s/-/$separator/g"
}

function Str:title() {
  # Str:title <input> <separator>
  # Str:title "Jack, Jill & Clémence LTD"     => JackJillClemenceLtd
  # Str:title "Jack, Jill & Clémence LTD" "_" => Jack_Jill_Clemence_Ltd
  separator="${2:-}"
  # shellcheck disable=SC2020
  Str:lower "$1" |
    tr 'àáâäæãåāçćčèéêëēėęîïííīįìłñńôöòóœøōõßśšûüùúūÿžźż' 'aaaaaaaaccceeeeeeeiiiiiiilnnoooooooosssuuuuuyzzz' |
    awk '{ gsub(/[\[\]@#$%^&*;,.:()<>!?\/+=_-]/," ",$0); print $0; }' |
    awk '{
          for (i=1; i<=NF; ++i) {
              $i = toupper(substr($i,1,1)) tolower(substr($i,2))
          };
          print $0;
          }' |
    sed "s/ /$separator/g" |
    cut -c1-50
}

function Str:digest() {
  local length=${1:-6}
  if [[ -n $(command -v md5sum) ]]; then
    # regular linux
    md5sum | cut -c1-"$length"
  else
    # macos
    md5 | cut -c1-"$length"
  fi
}

# Gha: function should only be run inside of a Github Action

function Gha:finish() {
  [[ -z "${RUNNER_OS:-}" ]] && IO:die "This should only run inside a Github Action, don't run it on your machine"
  local timestamp message
  git config user.name "Bashew Runner"
  git config user.email "actions@users.noreply.github.com"
  git add -A
  timestamp="$(date -u)"
  message="$timestamp < $script_basename $script_version"
  IO:print "Commit Message: $message"
  git commit -m "${message}" || exit 0
  git pull --rebase
  git push
  IO:success "Commit OK!"
}

trap "IO:die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$script_install_path awk -v lineno=\$LINENO \
'NR == lineno {print \"\${error_prefix} from line \" lineno \" : \" \$0}')" INT TERM EXIT
# cf https://askubuntu.com/questions/513932/what-is-the-bash-command-variable-good-for

Script:exit() {
  local temp_file
  for temp_file in "${temp_files[@]-}"; do
    [[ -f "$temp_file" ]] && (
      IO:debug "Delete temp file [$temp_file]"
      rm -f "$temp_file"
    )
  done
  trap - INT TERM EXIT
  IO:debug "$script_basename finished after $SECONDS seconds"
  exit 0
}

Script:check_version() {
  (
    # shellcheck disable=SC2164
    pushd "$script_install_folder" &>/dev/null
    if [[ -d .git ]]; then
      local remote
      remote="$(git remote -v | grep fetch | awk 'NR == 1 {print $2}')"
      IO:progress "Check for updates - $remote"
      git remote update &>/dev/null
      if [[ $(git rev-list --count "HEAD...HEAD@{upstream}" 2>/dev/null) -gt 0 ]]; then
        IO:print "There is a more recent update of this script - run <<$script_prefix update>> to update"
      else
        IO:progress "                                         "
      fi
    fi
    # shellcheck disable=SC2164
    popd &>/dev/null
  )
}

Script:git_pull() {
  # run in background to avoid problems with modifying a running interpreted script
  (
    sleep 1
    cd "$script_install_folder" && git pull
  ) &
}

Script:show_tips() {
  ((sourced)) && return 0
  # shellcheck disable=SC2016
  grep <"${BASH_SOURCE[0]}" -v '$0' |
    awk \
      -v green="$txtInfo" \
      -v yellow="$txtWarn" \
      -v reset="$txtReset" \
      '
      /TIP: /  {$1=""; gsub(/«/,green); gsub(/»/,reset); print "*" $0}
      /TIP:> / {$1=""; print " " yellow $0 reset}
      ' |
    awk \
      -v script_basename="$script_basename" \
      -v script_prefix="$script_prefix" \
      '{
      gsub(/\$script_basename/,script_basename);
      gsub(/\$script_prefix/,script_prefix);
      print ;
      }'
}

Script:check() {
  local name
  if [[ -n $(Option:filter flag) ]]; then
    IO:print "## ${txtInfo}boolean flags${txtReset}:"
    Option:filter flag |
      grep -v help |
      while read -r name; do
        declare -p "$name" | cut -d' ' -f3-
      done
  fi

  if [[ -n $(Option:filter option) ]]; then
    IO:print "## ${txtInfo}option defaults${txtReset}:"
    Option:filter option |
      while read -r name; do
        declare -p "$name" | cut -d' ' -f3-
      done
  fi

  if [[ -n $(Option:filter list) ]]; then
    IO:print "## ${txtInfo}list options${txtReset}:"
    Option:filter list |
      while read -r name; do
        declare -p "$name" | cut -d' ' -f3-
      done
  fi

  if [[ -n $(Option:filter param) ]]; then
    if ((piped)); then
      IO:debug "Skip parameters for .env files"
    else
      IO:print "## ${txtInfo}parameters${txtReset}:"
      Option:filter param |
        while read -r name; do
          declare -p "$name" | cut -d' ' -f3-
        done
    fi
  fi

  if [[ -n $(Option:filter choice) ]]; then
    if ((piped)); then
      IO:debug "Skip choices for .env files"
    else
      IO:print "## ${txtInfo}choice${txtReset}:"
      Option:filter choice |
        while read -r name; do
          declare -p "$name" | cut -d' ' -f3-
        done
    fi
  fi

  IO:print "## ${txtInfo}required commands${txtReset}:"
  Script:show_required
}

Option:usage() {
  IO:print "Program : ${txtInfo}$script_basename${txtReset}  by ${txtWarn}$script_author${txtReset}"
  IO:print "Version : ${txtInfo}v$script_version${txtReset} (${txtWarn}$script_modified${txtReset})"
  IO:print "Purpose : ${txtInfo}$script_description${txtReset}"
  echo -n "Usage   : $script_basename"
  Option:config |
    awk '
  BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [flag] %s [default: off]",$2,$3,$4) ;
    oneline  = oneline " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [option] %s",$2,$3 " <?>",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /list/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [list] %s (array)",$2,$3 " <?>",$4) ;
    fulltext = fulltext "  [default empty]";
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secret] %s",$2,$3,"?",$4) ;
      oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s","<"$3">",$4);
          oneline  = oneline " <" $3 ">"
     }
     if($2 == "?"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s (optional)","<"$3">",$4);
          oneline  = oneline " <" $3 "?>"
     }
     if($2 == "n"){
          fulltext = fulltext sprintf("\n    %-17s: [parameters] %s (1 or more)","<"$3">",$4);
          oneline  = oneline " <" $3 " …>"
     }
    }
  $1 ~ /choice/ {
        fulltext = fulltext sprintf("\n    %-17s: [choice] %s","<"$3">",$4);
        if($5!=""){fulltext = fulltext "  [options: " $5 "]"; }
        oneline  = oneline " <" $3 ">"
    }
    END {print oneline; print fulltext}
  '
}

function Option:filter() {
  Option:config | grep "$1|" | cut -d'|' -f3 | sort | grep -v '^\s*$'
}

function Script:show_required() {
  grep 'Os:require' "$script_install_path" |
    grep -v -E '\(\)|grep|# Os:require' |
    awk -v install="# $install_package " '
    function ltrim(s) { sub(/^[ "\t\r\n]+/, "", s); return s }
    function rtrim(s) { sub(/[ "\t\r\n]+$/, "", s); return s }
    function trim(s) { return rtrim(ltrim(s)); }
    NF == 2 {print install trim($2); }
    NF == 3 {print install trim($3); }
    NF > 3  {$1=""; $2=""; $0=trim($0); print "# " trim($0);}
  ' |
    sort -u
}

function Option:initialize() {
  local init_command
  init_command=$(Option:config |
    grep -v "VERBOSE|" |
    awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3 "=0; "}
    $1 ~ /flag/   && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /option/ && $5 == "" {print $3 "=\"\"; "}
    $1 ~ /option/ && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /choice/   {print $3 "=\"\"; "}
    $1 ~ /list/     {print $3 "=(); "}
    $1 ~ /secret/   {print $3 "=\"\"; "}
    ')
  if [[ -n "$init_command" ]]; then
    eval "$init_command"
  fi
}

function Option:has_single() { Option:config | grep 'param|1|' >/dev/null; }
function Option:has_choice() { Option:config | grep 'choice|1' >/dev/null; }
function Option:has_optional() { Option:config | grep 'param|?|' >/dev/null; }
function Option:has_multi() { Option:config | grep 'param|n|' >/dev/null; }

function Option:parse() {
  if [[ $# -eq 0 ]]; then
    Option:usage >&2
    Script:exit
  fi

  ## first process all the -x --xxxx flags and options
  while true; do
    # flag <flag> is saved as $flag = 0/1
    # option <option> is saved as $option
    if [[ $# -eq 0 ]]; then
      ## all parameters processed
      break
    fi
    if [[ ! $1 == -?* ]]; then
      ## all flags/options processed
      break
    fi
    local save_option
    save_option=$(Option:config |
      awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=${2:-}; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=${2:-}; shift"}
        $1 ~ /list/ &&  "-"$2 == opt {print $3"+=(${2:-}); shift"}
        $1 ~ /list/ && "--"$3 == opt {print $3"=(${2:-}); shift"}
        $1 ~ /secret/ &&  "-"$2 == opt {print $3"=${2:-}; shift #noshow"}
        $1 ~ /secret/ && "--"$3 == opt {print $3"=${2:-}; shift #noshow"}
        ')
    if [[ -n "$save_option" ]]; then
      if echo "$save_option" | grep shift >>/dev/null; then
        local save_var
        save_var=$(echo "$save_option" | cut -d= -f1)
        IO:debug "$config_icon parameter: ${save_var}=$2"
      else
        IO:debug "$config_icon flag: $save_option"
      fi
      eval "$save_option"
    else
      IO:die "cannot interpret option [$1]"
    fi
    shift
  done

  ((help)) && (
    Option:usage
    Script:check_version
    IO:print "                                  "
    echo "### TIPS & EXAMPLES"
    Script:show_tips

  ) && Script:exit

  local option_list
  local option_count
  local choices
  local single_params
  ## then run through the given parameters
  if Option:has_choice; then
    choices=$(Option:config | awk -F"|" '
      $1 == "choice" && $2 == 1 {print $3}
      ')
    option_list=$(xargs <<<"$choices")
    option_count=$(wc <<<"$choices" -w | xargs)
    IO:debug "$config_icon Expect : $option_count choice(s): $option_list"
    [[ $# -eq 0 ]] && IO:die "need the choice(s) [$option_list]"

    local choices_list
    local valid_choice
    local param
    for param in $choices; do
      [[ $# -eq 0 ]] && IO:die "need choice [$param]"
      [[ -z "$1" ]] && IO:die "need choice [$param]"
      IO:debug "$config_icon Assign : $param=$1"
      # check if choice is in list
      choices_list=$(Option:config | awk -F"|" -v choice="$param" '$1 == "choice" && $3 = choice {print $5}')
      valid_choice=$(tr <<<"$choices_list" "," "\n" | grep "$1")
      [[ -z "$valid_choice" ]] && IO:die "choice [$1] is not valid, should be in list [$choices_list]"

      eval "$param=\"$1\""
      shift
    done
  else
    IO:debug "$config_icon No choices to process"
    choices=""
    option_count=0
  fi

  if Option:has_single; then
    single_params=$(Option:config | awk -F"|" '
      $1 == "param" && $2 == 1 {print $3}
      ')
    option_list=$(xargs <<<"$single_params")
    option_count=$(wc <<<"$single_params" -w | xargs)
    IO:debug "$config_icon Expect : $option_count single parameter(s): $option_list"
    [[ $# -eq 0 ]] && IO:die "need the parameter(s) [$option_list]"

    for param in $single_params; do
      [[ $# -eq 0 ]] && IO:die "need parameter [$param]"
      [[ -z "$1" ]] && IO:die "need parameter [$param]"
      IO:debug "$config_icon Assign : $param=$1"
      eval "$param=\"$1\""
      shift
    done
  else
    IO:debug "$config_icon No single params to process"
    single_params=""
    option_count=0
  fi

  if Option:has_optional; then
    local optional_params
    local optional_count
    optional_params=$(Option:config | grep 'param|?|' | cut -d'|' -f3)
    optional_count=$(wc <<<"$optional_params" -w | xargs)
    IO:debug "$config_icon Expect : $optional_count optional parameter(s): $(echo "$optional_params" | xargs)"

    for param in $optional_params; do
      IO:debug "$config_icon Assign : $param=${1:-}"
      eval "$param=\"${1:-}\""
      shift
    done
  else
    IO:debug "$config_icon No optional params to process"
    optional_params=""
    optional_count=0
  fi

  if Option:has_multi; then
    #IO:debug "Process: multi param"
    local multi_count
    local multi_param
    multi_count=$(Option:config | grep -c 'param|n|')
    multi_param=$(Option:config | grep 'param|n|' | cut -d'|' -f3)
    IO:debug "$config_icon Expect : $multi_count multi parameter: $multi_param"
    ((multi_count > 1)) && IO:die "cannot have >1 'multi' parameter: [$multi_param]"
    ((multi_count > 0)) && [[ $# -eq 0 ]] && IO:die "need the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]]; then
      IO:debug "$config_icon Assign : $multi_param=$*"
      eval "$multi_param=( $* )"
    fi
  else
    multi_count=0
    multi_param=""
    [[ $# -gt 0 ]] && IO:die "cannot interpret extra parameters"
  fi
}

function Os:require() {
  local install_instructions
  local binary
  local words
  local path_binary
  # $1 = binary that is required
  binary="$1"
  path_binary=$(command -v "$binary" 2>/dev/null)
  [[ -n "$path_binary" ]] && IO:debug "️$require_icon required [$binary] -> $path_binary" && return 0
  # $2 = how to install it
  IO:alert "$script_basename needs [$binary] but it cannot be found"
  words=$(echo "${2:-}" | wc -w)
  install_instructions="$install_package $1"
  [[ $words -eq 1 ]] && install_instructions="$install_package $2"
  [[ $words -gt 1 ]] && install_instructions="${2:-}"
  if ((FORCE)); then
    IO:announce "Installing [$1] ..."
    eval "$install_instructions"
  else
    IO:alert "1) install package  : $install_instructions"
    IO:alert "2) check path       : export PATH=\"[path of your binary]:\$PATH\""
    IO:die "Missing program/script [$binary]"
  fi
}

function Os:folder() {
  if [[ -n "$1" ]]; then
    local folder="$1"
    local max_days=${2:-365}
    if [[ ! -d "$folder" ]]; then
      IO:debug "$clean_icon Create folder : [$folder]"
      mkdir -p "$folder"
    else
      IO:debug "$clean_icon Cleanup folder: [$folder] - delete files older than $max_days day(s)"
      find "$folder" -mtime "+$max_days" -type f -exec rm {} \;
    fi
  fi
}

function Os:follow_link() {
  [[ ! -L "$1" ]] && echo "$1" && return 0 ## if it's not a symbolic link, return immediately
  local file_folder link_folder link_name symlink
  file_folder="$(dirname "$1")"                                                                                   ## check if file has absolute/relative/no path
  [[ "$file_folder" != /* ]] && file_folder="$(cd -P "$file_folder" &>/dev/null && pwd)"                          ## a relative path was given, resolve it
  symlink=$(readlink "$1")                                                                                        ## follow the link
  link_folder=$(dirname "$symlink")                                                                               ## check if link has absolute/relative/no path
  [[ -z "$link_folder" ]] && link_folder="$file_folder"                                                           ## if no link path, stay in same folder
  [[ "$link_folder" == \.* ]] && link_folder="$(cd -P "$file_folder" && cd -P "$link_folder" &>/dev/null && pwd)" ## a relative link path was given, resolve it
  link_name=$(basename "$symlink")
  IO:debug "$info_icon Symbolic ln: $1 -> [$link_folder/$link_name]"
  Os:follow_link "$link_folder/$link_name" ## recurse
}

function Os:notify() {
  # cf https://levelup.gitconnected.com/5-modern-bash-scripting-techniques-that-only-a-few-programmers-know-4abb58ddadad
  local message="$1"
  local source="${2:-$script_basename}"

  [[ -n $(command -v notify-send) ]] && notify-send "$source" "$message"                                      # for Linux
  [[ -n $(command -v osascript) ]] && osascript -e "display notification \"$message\" with title \"$source\"" # for MacOS
}

function Os:busy() {
  # show spinner as long as process $pid is running
  local pid="$1"
  local message="${2:-}"
  local frames=("|" "/" "-" "\\")
  (
    while kill -0 "$pid" &>/dev/null; do
      for frame in "${frames[@]}"; do
        printf "\r[ $frame ] %s..." "$message"
        sleep 0.5
      done
    done
    printf "\n"
  )
}

function Os:beep() {
  if [[ -n "$TERM" ]]; then
    tput bel
  fi
}

function Script:meta() {

  script_prefix=$(basename "${BASH_SOURCE[0]}" .sh)
  script_basename=$(basename "${BASH_SOURCE[0]}")
  execution_day=$(date "+%Y-%m-%d")

  script_install_path="${BASH_SOURCE[0]}"
  IO:debug "$info_icon Script path: $script_install_path"
  script_install_path=$(Os:follow_link "$script_install_path")
  IO:debug "$info_icon Linked path: $script_install_path"
  script_install_folder="$(cd -P "$(dirname "$script_install_path")" && pwd)"
  IO:debug "$info_icon In folder  : $script_install_folder"
  if [[ -f "$script_install_path" ]]; then
    script_hash=$(Str:digest <"$script_install_path" 8)
    script_lines=$(awk <"$script_install_path" 'END {print NR}')
  fi

  # get shell/operating system/versions
  shell_brand="sh"
  shell_version="?"
  [[ -n "${ZSH_VERSION:-}" ]] && shell_brand="zsh" && shell_version="$ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && shell_brand="bash" && shell_version="$BASH_VERSION"
  [[ -n "${FISH_VERSION:-}" ]] && shell_brand="fish" && shell_version="$FISH_VERSION"
  [[ -n "${KSH_VERSION:-}" ]] && shell_brand="ksh" && shell_version="$KSH_VERSION"
  IO:debug "$info_icon Shell type : $shell_brand - version $shell_version"
  if [[ "$shell_brand" == "bash" && "${BASH_VERSINFO:-0}" -lt 4 ]]; then
    IO:die "Bash version 4 or higher is required - current version = ${BASH_VERSINFO:-0}"
  fi

  os_kernel=$(uname -s)
  os_version=$(uname -r)
  os_machine=$(uname -m)
  install_package=""
  case "$os_kernel" in
  CYGWIN* | MSYS* | MINGW*)
    os_name="Windows"
    ;;
  Darwin)
    os_name=$(sw_vers -productName)       # macOS
    os_version=$(sw_vers -productVersion) # 11.1
    install_package="brew install"
    ;;
  Linux | GNU*)
    if [[ $(command -v lsb_release) ]]; then
      # 'normal' Linux distributions
      os_name=$(lsb_release -i | awk -F: '{$1=""; gsub(/^[\s\t]+/,"",$2); gsub(/[\s\t]+$/,"",$2); print $2}')    # Ubuntu/Raspbian
      os_version=$(lsb_release -r | awk -F: '{$1=""; gsub(/^[\s\t]+/,"",$2); gsub(/[\s\t]+$/,"",$2); print $2}') # 20.04
    else
      # Synology, QNAP,
      os_name="Linux"
    fi
    [[ -x /bin/apt-cyg ]] && install_package="apt-cyg install"     # Cygwin
    [[ -x /bin/dpkg ]] && install_package="dpkg -i"                # Synology
    [[ -x /opt/bin/ipkg ]] && install_package="ipkg install"       # Synology
    [[ -x /usr/sbin/pkg ]] && install_package="pkg install"        # BSD
    [[ -x /usr/bin/pacman ]] && install_package="pacman -S"        # Arch Linux
    [[ -x /usr/bin/zypper ]] && install_package="zypper install"   # Suse Linux
    [[ -x /usr/bin/emerge ]] && install_package="emerge"           # Gentoo
    [[ -x /usr/bin/yum ]] && install_package="yum install"         # RedHat RHEL/CentOS/Fedora
    [[ -x /usr/bin/apk ]] && install_package="apk add"             # Alpine
    [[ -x /usr/bin/apt-get ]] && install_package="apt-get install" # Debian
    [[ -x /usr/bin/apt ]] && install_package="apt install"         # Ubuntu
    ;;

  esac
  IO:debug "$info_icon System OS  : $os_name ($os_kernel) $os_version on $os_machine"
  IO:debug "$info_icon Package mgt: $install_package"

  # get last modified date of this script
  script_modified="??"
  [[ "$os_kernel" == "Linux" ]] && script_modified=$(stat -c %y "$script_install_path" 2>/dev/null | cut -c1-16) # generic linux
  [[ "$os_kernel" == "Darwin" ]] && script_modified=$(stat -f "%Sm" "$script_install_path" 2>/dev/null)          # for MacOS

  IO:debug "$info_icon Version  : $script_version"
  IO:debug "$info_icon Created  : $script_created"
  IO:debug "$info_icon Modified : $script_modified"

  IO:debug "$info_icon Lines    : $script_lines lines / md5: $script_hash"
  IO:debug "$info_icon User     : $USER@$HOSTNAME"

  # if run inside a git repo, detect for which remote repo it is
  if git status &>/dev/null; then
    git_repo_remote=$(git remote -v | awk '/(fetch)/ {print $2}')
    IO:debug "$info_icon git remote : $git_repo_remote"
    git_repo_root=$(git rev-parse --show-toplevel)
    IO:debug "$info_icon git folder : $git_repo_root"
  fi

  # get script version from VERSION.md file - which is automatically updated by pforret/setver
  [[ -f "$script_install_folder/VERSION.md" ]] && script_version=$(cat "$script_install_folder/VERSION.md")
  # get script version from git tag file - which is automatically updated by pforret/setver
  [[ -n "$git_repo_root" ]] && [[ -n "$(git tag &>/dev/null)" ]] && script_version=$(git tag --sort=version:refname | tail -1)
}

function Script:initialize() {
  log_file=""
  if [[ -n "${TMP_DIR:-}" ]]; then
    # clean up TMP folder after 1 day
    Os:folder "$TMP_DIR" 1
  fi
  if [[ -n "${LOG_DIR:-}" ]]; then
    # clean up LOG folder after 1 month
    Os:folder "$LOG_DIR" 30
    log_file="$LOG_DIR/$script_prefix.$execution_day.log"
    IO:debug "$config_icon log_file: $log_file"
  fi
}

function Os:tempfile() {
  local extension=${1:-txt}
  local file="${TMP_DIR:-/tmp}/$execution_day.$RANDOM.$extension"
  IO:debug "$config_icon tmp_file: $file"
  temp_files+=("$file")
  echo "$file"
}

function Os:import_env() {
  local env_files
  if [[ $(pwd) == "$script_install_folder" ]]; then
    env_files=(
      "$script_install_folder/.env"
      "$script_install_folder/.$script_prefix.env"
      "$script_install_folder/$script_prefix.env"
    )
  else
    env_files=(
      "$script_install_folder/.env"
      "$script_install_folder/.$script_prefix.env"
      "$script_install_folder/$script_prefix.env"
      "./.env"
      "./.$script_prefix.env"
      "./$script_prefix.env"
    )
  fi

  local env_file
  for env_file in "${env_files[@]}"; do
    if [[ -f "$env_file" ]]; then
      IO:debug "$config_icon Read  dotenv: [$env_file]"
      local clean_file
      clean_file=$(Os:clean_env "$env_file")
      # shellcheck disable=SC1090
      source "$clean_file" && rm "$clean_file"
    fi
  done
}

function Os:clean_env() {
  local input="$1"
  local output="$1.__.sh"
  [[ ! -f "$input" ]] && IO:die "Input file [$input] does not exist"
  IO:debug "$clean_icon Clean dotenv: [$output]"
  awk <"$input" '
      function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
      function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
      function trim(s) { return rtrim(ltrim(s)); }
      /=/ { # skip lines with no equation
        $0=trim($0);
        if(substr($0,1,1) != "#"){ # skip comments
          equal=index($0, "=");
          key=trim(substr($0,1,equal-1));
          val=trim(substr($0,equal+1));
          if(match(val,/^".*"$/) || match(val,/^\047.*\047$/)){
            print key "=" val
          } else {
            print key "=\"" val "\""
          }
        }
      }
  ' >"$output"
  echo "$output"
}

IO:initialize # output settings
Script:meta   # find installation folder

[[ $run_as_root == 1 ]] && [[ $UID -ne 0 ]] && IO:die "user is $USER, MUST be root to run [$script_basename]"
[[ $run_as_root == -1 ]] && [[ $UID -eq 0 ]] && IO:die "user is $USER, CANNOT be root to run [$script_basename]"

Option:initialize # set default values for flags & options
Os:import_env     # load .env, .<prefix>.env, <prefix>.env (script folder + cwd)

if [[ $sourced -eq 0 ]]; then
  Option:parse "$@" # overwrite with specified options if any
  Script:initialize # clean up folders
  Script:main       # run Script:main program
  Script:exit       # exit and clean up
else
  # just disable the trap, don't execute Script:main
  trap - INT TERM EXIT
fi
