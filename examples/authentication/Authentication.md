# Authentication Example

Demonstrates authentication with AWS S3 using static credentials.

## Configuration

Create `Config.toml`:

```toml
accessKeyId = "YOUR_ACCESS_KEY_ID"
secretAccessKey = "YOUR_SECRET_ACCESS_KEY"
```

## Run

```bash
bal run
```

## What It Does

1. Creates S3 client with provided credentials
2. Lists all buckets to verify authentication
3. Displays bucket count
