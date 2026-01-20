# Multipart Uploads Example

Demonstrates multipart upload for handling large files in S3.

## Configuration

Create `Config.toml`:

```toml
accessKeyId = "YOUR_ACCESS_KEY_ID"
secretAccessKey = "YOUR_SECRET_ACCESS_KEY"
bucketName = "my-multipart-bucket"
```

## Run

```bash
bal run
```

## What It Does

1. Creates a test bucket
2. Initiates multipart upload
3. Uploads 3 parts:
   - Part 1: 5MB
   - Part 2: 5MB
   - Part 3: 1MB (last part)
4. Completes multipart upload
5. Cleans up resources

## Multipart Upload Process

### Step 1: Create Multipart Upload
```ballerina
string uploadId = check s3Client->createMultipartUpload(bucket, key);
```

### Step 2: Upload Parts
```ballerina
byte[] partData = ...; // Minimum 5MB except last part
string etag = check s3Client->uploadPart(bucket, key, uploadId, partNumber, partData);
```

### Step 3: Complete Upload
```ballerina
check s3Client->completeMultipartUpload(bucket, key, uploadId, partNumbers, etags);
```

## When to Use Multipart Upload

- Files larger than 100 MB
- Large files over unreliable networks
- Need to upload parts in parallel
- Want to resume failed uploads

## Error Handling

To abort a failed upload:

```ballerina
string uploadId = check s3Client->createMultipartUpload(bucket, key);
do {
    // Upload parts...
    check s3Client->completeMultipartUpload(bucket, key, uploadId, partNumbers, etags);
} on fail error e {
    check s3Client->abortMultipartUpload(bucket, key, uploadId);
}
```
