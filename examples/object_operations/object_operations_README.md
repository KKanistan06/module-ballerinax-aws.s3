# Object Operations Example

Comprehensive demonstration of S3 object operations including uploads, downloads, metadata, copying, and management.

## Configuration

Create `Config.toml`:

```toml
accessKeyId = "YOUR_ACCESS_KEY_ID"
secretAccessKey = "YOUR_SECRET_ACCESS_KEY"
bucketName = "my-object-bucket"
```

## Run

```bash
bal run
```

## Operations Demonstrated

### 1. Upload Objects (putObject)
Upload different content types:

**String:**
```ballerina
string content = "Hello World!";
check s3Client->putObject(bucket, "file.txt", content);
```

**JSON:**
```ballerina
json data = {"key": "value"};
check s3Client->putObject(bucket, "data.json", data);
```

**XML:**
```ballerina
xml data = xml `<root><item>value</item></root>`;
check s3Client->putObject(bucket, "config.xml", data);
```

**Byte Array:**
```ballerina
byte[] data = [72, 101, 108, 108, 111];
check s3Client->putObject(bucket, "file.bin", data);
```

### 2. Download Objects (getObject)
Retrieve with automatic type conversion:

```ballerina
string text = check s3Client->getObject(bucket, "file.txt", string);
json data = check s3Client->getObject(bucket, "data.json", json);
xml config = check s3Client->getObject(bucket, "config.xml", xml);
byte[] binary = check s3Client->getObject(bucket, "file.bin");
```

### 3. Get Object Metadata (getObjectMetadata)
Get properties without downloading:

```ballerina
s3:ObjectMetadata metadata = check s3Client->getObjectMetadata(bucket, key);
io:println("Size: " + metadata.contentLength.toString());
io:println("Content Type: " + (metadata.contentType ?: "N/A"));
io:println("Last Modified: " + metadata.lastModified);
```

### 4. Check Object Existence (doesObjectExist)
Verify if object exists:

```ballerina
boolean exists = check s3Client->doesObjectExist(bucket, key);
```

### 5. Copy Objects (copyObject)
Duplicate objects within or across buckets:

```ballerina
check s3Client->copyObject(sourceBucket, sourceKey, destBucket, destKey);
```

### 6. List Objects (listObjects)
Enumerate bucket contents:

```ballerina
s3:ListObjectsResponse response = check s3Client->listObjects(bucket);
```

### 7. Delete Objects (deleteObject)
Remove objects from bucket:

```ballerina
check s3Client->deleteObject(bucket, key);
```
