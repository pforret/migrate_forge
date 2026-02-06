# Laravel Forge Migration Wizard

## Steps

### Step 1: Select the source server

* ✅  Source server: [old-server]
* ⏳  Connecting to [old-server] to list sites...

### Step 2: Select the site to migrate

* ✅  Source site: <old-site>

### Step 3: What to include in the migration?

* Include database dump? [Y/n]
* Include storage/app? [Y/n]

### Step 4: Select the destination server

* ✅  Destination server: [new-server]

### Step 5: Destination site

* ⏳  Connecting to [new-server] to list existing sites...
* ✅  Destination site: <new-site>

## Migration Plan

* Source : [old-server] -> /home/forge/<old-site>
* Dest   : [new-server] -> /home/forge/<new-site>
* Include: database=y, storage/app=y

### Step 1: Create backup on source server

```
ssh [old-server]
./migrate_forge.sh backup -d <old-site> -r /home/forge/<old-site>
```

### Step 2: Transfer archive to destination

```
scp [old-server]:/home/forge/<old-site>/migrate_*.zip /tmp/
scp /tmp/migrate_*.zip [new-server]:/tmp/
```

### Step 3: (Optional) Setup new site via Forge API

```
./migrate_forge.sh setup -d <old-site> -s <source_server_id> -D <dest_server_id>
(requires FORGE_API_TOKEN in .env)
```

### Step 4: Restore on destination server

```
ssh [new-server]
./migrate_forge.sh restore /tmp/migrate_*.zip -r /home/forge/<new-site>
```

### Step 5: Verify and update DNS

- Review .env on destination (especially DB credentials)
- Test the site on the new server
- Update DNS records for <old-site> to point to [new-server]
- Wait for DNS propagation
- Request SSL certificate if not done in setup step

✅  Migration plan generated. Follow the steps above in order.
