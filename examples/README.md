# AWS S3 Connector Examples

This directory contains comprehensive examples demonstrating various features and use cases of the Ballerina AWS S3 connector.

## Examples by Category

### 1. [Authentication](authentication/)
Demonstrates how to authenticate with AWS S3 using static credentials.

**Features:**
- Static credentials (Access Key ID and Secret Access Key)
- Connection verification by listing buckets

### 2. [Bucket Operations](bucket-operations/)
Basic S3 bucket management operations.

**Features:**
- Create bucket
- List all buckets
- Get bucket location/region
- Delete bucket

### 3. [Object Operations](object-operations/)
Comprehensive S3 object operations with different content types.

**Features:**
- Upload objects (String, JSON, XML, Byte[])
- Download objects with type conversion
- Get object metadata
- Check object existence
- Copy objects
- List objects
- Delete objects

### 4. [Multipart Uploads](multipart-uploads/)
Handle large file uploads using S3 multipart upload API.

**Features:**
- Create multipart upload
- Upload parts (5MB + 5MB + 1MB)
- Complete multipart upload
- Helper function to generate test data

### 5. [Stream Operations](stream-operations/)
Memory-efficient streaming operations for large files.

**Features:**
- Stream upload (putObjectAsStream)
- Stream download (getObjectAsStream)
- Stream multipart upload (uploadPartAsStream)

## Prerequisites

- Ballerina Swan Lake Update 8 or later
- AWS Account with S3 access
- AWS Access Key ID and Secret Access Key

## Configuration

Each example requires a `Config.toml` file with your AWS credentials:

```toml
accessKeyId = "YOUR_ACCESS_KEY_ID"
secretAccessKey = "YOUR_SECRET_ACCESS_KEY"
bucketName = "your-bucket-name"
```

**Important:** Never commit `Config.toml` files with real credentials to version control.

## Running an Example

Execute the following commands to build and run an example:

### To build an example

```bash
cd <example-name>
bal build
```

### To run an example

```bash
cd <example-name>
bal run
```

Or with inline configuration:

```bash
bal run -- -CaccessKeyId=YOUR_KEY -CsecretAccessKey=YOUR_SECRET -CbucketName=your-bucket
```

## Quick Start

### Example 1: Authentication

```bash
cd authentication
bal run
```

### Example 2: Bucket Operations

```bash
cd bucket-operations
bal run
```

### Example 3: Object Operations

```bash
cd object-operations
bal run
```

### Example 4: Multipart Uploads

```bash
cd multipart-uploads
bal run
```

### Example 5: Stream Operations

```bash
cd stream-operations
bal run
```

## Building the Examples with the Local Module

**Warning:** Because of the absence of support for reading local repositories for single Ballerina files, the bala of
the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your
local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

### To build all the examples

```bash
./build.sh build
```

### To run all the examples

```bash
./build.sh run
```
