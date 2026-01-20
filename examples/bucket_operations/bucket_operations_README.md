# Bucket Operations Example

Demonstrates basic S3 bucket management operations.

## Configuration

Create `Config.toml`:

```toml
accessKeyId = "YOUR_ACCESS_KEY_ID"
secretAccessKey = "YOUR_SECRET_ACCESS_KEY"
bucketName = "my-test-bucket-12345"
```

**Note:** Bucket names must be globally unique across all AWS accounts.

## Run

```bash
bal run
```

## What It Does

1. Creates a new S3 bucket
2. Lists all buckets in your account
3. Gets the bucket location (AWS region)
4. Deletes the bucket

## Bucket Naming Rules

- Must be globally unique
- 3-63 characters long
- Lowercase letters, numbers, hyphens only
- Must start with letter or number
- Cannot be formatted as IP address