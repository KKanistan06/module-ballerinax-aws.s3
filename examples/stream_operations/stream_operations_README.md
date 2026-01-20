# Stream Operations Example

Demonstrates efficient streaming operations for uploads and downloads in S3.

## Configuration

Create `Config.toml`:

```toml
accessKeyId = "YOUR_ACCESS_KEY_ID"
secretAccessKey = "YOUR_SECRET_ACCESS_KEY"
bucketName = "my-stream-bucket"
```

## Run

```bash
bal run
```

## What It Does

1. **putObjectAsStream** - Uploads object using streaming (memory efficient)
2. **getObjectAsStream** - Downloads object using streaming
3. **uploadPartAsStream** - Uploads multipart parts using streaming

## Operations Demonstrated

### 1. Stream Upload (putObjectAsStream)
Upload data without loading entire file into memory:

```ballerina
byte[] data = "Hello World!".toBytes();
stream<byte[], error?> uploadStream = [data].toStream();

check s3Client->putObjectAsStream(
    bucket, 
    key, 
    uploadStream, 
    contentLength = data.length()
);
```

### 2. Stream Download (getObjectAsStream)
Download large files efficiently:

```ballerina
stream<byte[], error?> downloadStream = check s3Client->getObjectAsStream(bucket, key);

int totalBytes = 0;
check from byte[] chunk in downloadStream
    do {
        totalBytes += chunk.length();
        // Process chunk without loading entire file
    };
```

### 3. Stream Multipart Upload (uploadPartAsStream)
Upload large files in parts using streams:

```ballerina
string uploadId = check s3Client->createMultipartUpload(bucket, key);

byte[] partData = ...; // Part data
stream<byte[], error?> partStream = [partData].toStream();

string etag = check s3Client->uploadPartAsStream(
    bucket, 
    key, 
    uploadId, 
    partNumber, 
    partStream,
    contentLength = partData.length()
);

check s3Client->completeMultipartUpload(bucket, key, uploadId, partNumbers, etags);
```
