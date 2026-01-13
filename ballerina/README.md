## Overview

[Amazon Simple Storage Service (Amazon S3)](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html) is a highly scalable, durable object storage service for storing and retrieving any amount of data.

The `ballerinax/aws.s3` connector enables Ballerina applications to interact with Amazon S3. It supports bucket management (create, list, delete), object operations (upload, download, copy, delete, metadata), streaming for large files, multipart uploads, presigned URLs, and flexible content retrieval with typed returns.

## Setup guide

### Login to AWS Console

Log into the [AWS Management Console](https://console.aws.amazon.com/console). If you don’t have an AWS account yet, you can create one by visiting the AWS [sign-up](https://aws.amazon.com/free/) page. Sign up is free, and you can explore many services under the Free Tier.

### Create a user

1. In the AWS Management Console, search for IAM in the services search bar.
2. Click on IAM

   ![create-user-1.png](../docs/setup/resources/create-user-1.jpeg)

3. Click Users

   ![create-user-2.png](../docs/setup/resources/create-user-2.jpeg)

4. Click Create User

   ![create-user-3.png](../docs/setup/resources/create-user-3.jpeg)

5. Provide a suitable name for the user and continue

   ![specify-user-details.png](../docs/setup/resources/specify-user-details.jpeg)

6. Add necessary permissions by adding the user to a user group, copy permissions or directly attach the policies. For S3, attach policies such as `AmazonS3FullAccess` (for development) or a least-privilege custom policy scoped to your buckets. Then click next.

   ![set-user-permissions.png](../docs/setup/resources/set-user-permissions.jpeg)
7. Review and create the user

   ![review-create-user.png](../docs/setup/resources/review-create-user.jpeg)

### Get user access keys

1. Click the user that was created.

   ![users.png](../docs/setup/resources/users.jpeg)

2. Click `Create access key`.

   ![create-access-key-1.png](../docs/setup/resources/create-access-key-1.png)

3. Select your use case and click next.

   ![select-usecase.png](../docs/setup/resources/select-usecase.png)

4. Record the Access Key ID and Secret Access Key. These credentials will be used to authenticate your Ballerina application with Amazon S3.

   ![retrieve-access-key.png](../docs/setup/resources/retrieve-access-key.png)

## Quickstart

To use the `aws.s3` connector in your Ballerina project, modify the `.bal` file as follows.

### Step 1: Import the module

```ballerina
import ballerinax/aws.s3;
```

### Step 2: Instantiate a new connector

Create a new `s3:Client` by providing the region and authentication configurations.

```ballerina
configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;

s3:Client s3Client = check new ({
   region: "us-east-1",
   auth: {
      accessKeyId,
      secretAccessKey
   }
});
```

#### Alternative authentication methods

##### Profile-based authentication

You can use AWS profile-based authentication as an alternative to static credentials.

```ballerina
s3:Client s3Client = check new ({
   region: "us-east-1",
   auth: {
      profileName: "myAwsProfile",
      credentialsFilePath: "/path/to/custom/credentials"
   }
});
```

> **Note:** Ensure your AWS credentials file follows the standard format.
>
> ```ini
> [default]
> aws_access_key_id = YOUR_ACCESS_KEY_ID
> aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
>
> [myAwsProfile]
> aws_access_key_id = ANOTHER_ACCESS_KEY_ID
> aws_secret_access_key = ANOTHER_SECRET_ACCESS_KEY
> ```


### Step 3: Invoke the connector operations

Now, utilize the available connector operations.

#### Create a bucket
```ballerina
check s3Client->createBucket("my-s3-bucket");
```

#### Upload an object
```ballerina
// Upload from content
check s3Client->putObject("my-s3-bucket", "docs/readme.txt", "Hello from Ballerina!");

// Upload from a file path
check s3Client->putObjectFromFile("my-s3-bucket", "images/logo.png", "/path/to/logo.png");
```

#### Download an object (typed)
```ballerina
// Return as byte array
byte[] bytes = check s3Client->getObject("my-s3-bucket", "docs/readme.txt", Bytes);

// Return as string
string text = check s3Client->getObject("my-s3-bucket", "docs/readme.txt", string);

// Return as json
json data = check s3Client->getObject("my-s3-bucket", "data.json", json);

// Return as xml (using alias)
xml x = check s3Client->getObject("my-s3-bucket", "data.xml", Xml);
```

#### Download an object as a stream (for large files)
```ballerina
stream<byte[], error?> content = check s3Client->getObjectAsStream("my-s3-bucket", "videos/movie.mp4");
// Consume the stream in chunks
final byte[]? next = (); // placeholder to illustrate stream consumption
```

#### List and delete objects
```ballerina
// List objects in a bucket
aws.s3:ListObjectsResponse resp = check s3Client->listObjects("my-s3-bucket", {
   prefix: "docs/",
   maxKeys: 100
});

// Delete an object
check s3Client->deleteObject("my-s3-bucket", "docs/readme.txt");
```

#### Bucket utilities
```ballerina
// List buckets
aws.s3:Bucket[] buckets = check s3Client->listBuckets();

// Get bucket region
string region = check s3Client->getBucketLocation("my-s3-bucket");

// Delete a bucket
check s3Client->deleteBucket("my-s3-bucket");
```

#### Multipart uploads
```ballerina
// 1) Start a multipart upload and get the upload ID
string uploadId = check s3Client->createMultipartUpload("my-s3-bucket", "large/video.mp4", {
   contentType: "video/mp4"
});

// 2) Upload parts
// 2a) Upload a part from in-memory content (byte[], string, json, xml)
byte[] firstChunk = [];
string etag1 = check s3Client->uploadPart(
   "my-s3-bucket", "large/video.mp4", uploadId, 1, firstChunk
);

// 2b) Upload a part from a stream (recommended for large parts)
stream<byte[], error?> part2Stream = (); // provide a stream of byte[] chunks
string etag2 = check s3Client->uploadPartAsStream(
   "my-s3-bucket", "large/video.mp4", uploadId, 2, part2Stream
);

// 3) Complete the multipart upload
// Part numbers and ETag order must match the uploaded parts
check s3Client->completeMultipartUpload(
   "my-s3-bucket", "large/video.mp4", uploadId, [1, 2], [etag1, etag2]
);

// Optional: Abort if you do not intend to complete the upload
// check s3Client->abortMultipartUpload("my-s3-bucket", "large/video.mp4", uploadId);
```

#### Presigned URLs
```ballerina
// Generate a presigned URL for downloading an object
string url = check s3Client->createPresignedUrl("my-s3-bucket", "docs/readme.txt", {
   expirationMinutes: 30,
   httpMethod: "GET"
});
```

### Step 4: Run the Ballerina application

Use the following command to compile and run the Ballerina program.

```bash
bal run
```

## Examples