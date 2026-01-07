// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;

# The AWS S3 Client Connector.
@display {label: "AWS S3 Client", iconPath: "icon.png"}
public isolated client class Client {

    # Initializes the S3 Client.
    #
    # + config - The connection configuration
    # + return - An Error if initialization fails
    public isolated function init(*ConnectionConfig config) returns Error? {
        return initClient(self, config);
    }

    # Creates an S3 bucket.
    #
    # + bucketName - The name of the bucket
    # + config - Optional bucket configuration
    # + return - An Error if bucket creation fails
    @display {label: "Create Bucket"}
    remote isolated function createBucket(@display {label: "Bucket Name"} string bucketName,
            *CreateBucketConfig config) returns Error? {
        check nativeCreateBucket(self, bucketName, config);
    }

    # Deletes an S3 bucket.
    #
    # + bucketName - The name of the bucket
    # + return - An Error if bucket deletion fails
    @display {label: "Delete Bucket"}
    remote isolated function deleteBucket(@display {label: "Bucket Name"} string bucketName) returns Error? {
        check nativeDeleteBucket(self, bucketName);
    }

    # Lists all buckets in the AWS account.
    #
    # + return - List of buckets or an Error
    @display {label: "List Buckets"}
    remote isolated function listBuckets() returns @display {label: "Bucket Names"} Bucket[]|Error {
        json result = check nativeListBuckets(self);
        Bucket[]|error buckets = result.fromJsonWithType();
        if buckets is error {
            return error Error(buckets.message(), buckets);
        }
        return buckets;
    }

    # Gets the AWS region of a bucket.
    #
    # + bucketName - The name of the bucket
    # + return - Region string or an Error
    @display {label: "Get Bucket Location"}
    remote isolated function getBucketLocation(@display {label: "Bucket Name"} string bucketName) 
            returns @display {label: "Region"} string|Error {
        return check nativeGetBucketLocation(self, bucketName);
    }

    # Uploads an S3 object from a file path.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + filePath - The local file path to upload
    # + config - Optional upload configuration
    # + return - An Error if the upload fails
    @display {label: "Put Object From File"}
    remote isolated function putObjectFromFile(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "File Path"} string filePath,
            *PutObjectConfig config) returns Error? {
        check nativePutObjectFromFile(self, bucketName, objectKey, filePath, config);
    }

    # Uploads an S3 object from content.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + content - The object content (string | xml | json | byte[])
    # + config - Optional upload configuration
    # + return - An Error if the upload fails
    @display {label: "Put Object"}
    remote isolated function putObject(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Content"} anydata content,
            *PutObjectConfig config) returns Error? {
        byte[] converted = toByteArray(content);
        check nativePutObjectWithContent(self, bucketName, objectKey, converted, config);
    }

    # Uploads an S3 object from a stream.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + contentStream - The content stream
    # + config - Optional upload configuration
    # + return - An Error if the upload fails
    @display {label: "Put Object As Stream"}
    remote isolated function putObjectAsStream(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Content Stream"} stream<byte[], error?> contentStream,
            *PutObjectConfig config) returns Error? {
        check nativePutObjectWithStream(self, bucketName, objectKey, contentStream, config);
    }

    # Downloads an S3 object as a stream.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + config - Optional retrieval configuration
    # + return - A stream of byte chunks containing the object content, or an Error
    @display {label: "Get Object As Stream"}
    remote isolated function getObjectAsStream(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            *GetObjectConfig config) 
            returns @display {label: "Byte Stream"} stream<byte[], Error?>|Error {
        S3StreamResult streamImpl = check nativeGetObject(self, bucketName, objectKey, config);
        return new stream<byte[], Error?>(streamImpl);
    }

    # Downloads an S3 object and returns its content in the specified type.
    # This method loads the entire object into memory and is suitable for smaller objects.
    # For large objects, consider using `getObjectAsStream` instead.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + targetType - The type to return the content as (Bytes, string, json, or xml). Defaults to Bytes
    # + config - Optional retrieval configuration
    # + return - The object content in the requested type, or an Error
    @display {label: "Get Object"}
    remote isolated function getObject(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Target Type"} typedesc<anydata> targetType = Bytes,
            *GetObjectConfig config) 
            returns @display {label: "Content"} targetType|Error = @java:Method {
        name: "getObjectWithType",
        'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
    } external;

    # Deletes an S3 object from an S3 bucket.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + config - Optional deletion configuration
    # + return - An Error if deletion fails
    @display {label: "Delete Object"}
    remote isolated function deleteObject(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            *DeleteObjectConfig config) returns Error? {
        check nativeDeleteObject(self, bucketName, objectKey, config);
    }

    # Lists S3 objects in an S3 bucket.
    #
    # + bucketName - The name of the bucket
    # + config - Optional listing configuration
    # + return - List of objects or an Error
    @display {label: "List Objects"}
    remote isolated function listObjects(@display {label: "Bucket Name"} string bucketName,
            *ListObjectsConfig config)
            returns @display {label: "Objects List"} ListObjectsResponse|Error {
        json result = check nativeListObjectsV2(self, bucketName, config);
        ListObjectsResponse|error response = result.fromJsonWithType();
        if response is error {
            return error Error(response.message(), response);
        }
        return response;
    }

    # Creates a presigned URL for temporary access to an S3 object.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + config - Optional presigned URL configuration
    # + return - Presigned URL string or an Error
    @display {label: "Create Presigned URL"}
    remote isolated function createPresignedUrl(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            *PresignedUrlConfig config) 
            returns @display {label: "Presigned URL"} string|Error {
        return check nativeCreatePresignedUrl(self, bucketName, objectKey, config);
    }

    # Gets metadata for an S3 object without downloading it.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + config - Optional metadata retrieval configuration
    # + return - Object metadata or an Error
    @display {label: "Get Object Metadata"}
    remote isolated function getObjectMetadata(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            *HeadObjectConfig config) 
            returns @display {label: "Metadata"} ObjectMetadata|Error {
        json result = check nativeHeadObject(self, bucketName, objectKey, config);
        ObjectMetadata|error metadata = result.fromJsonWithType();
        if metadata is error {
            return error Error(metadata.message(), metadata);
        }
        return metadata;
    }

    # Copies an S3 object from one location to another.
    #
    # + sourceBucket - Source bucket name
    # + sourceKey - Source object path
    # + destinationBucket - Destination bucket name
    # + destinationKey - Destination object path
    # + config - Optional copy configuration
    # + return - An Error if copy fails
    @display {label: "Copy Object"}
    remote isolated function copyObject(@display {label: "Source Bucket"} string sourceBucket,
            @display {label: "Source Key"} string sourceKey,
            @display {label: "Destination Bucket"} string destinationBucket,
            @display {label: "Destination Key"} string destinationKey,
            *CopyObjectConfig config) returns Error? {
        check nativeCopyObject(self, sourceBucket, sourceKey, destinationBucket, destinationKey, config);
    }

    # Checks if an S3 object exists in an S3 bucket.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + return - True if exists, false otherwise
    @display {label: "Does Object Exist"}
    remote isolated function doesObjectExist(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey) 
            returns @display {label: "Exists"} boolean {
        return nativeDoesObjectExist(self, bucketName, objectKey);
    }

    # Creates a multipart upload.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + config - Optional multipart upload configuration
    # + return - Upload ID or an Error
    @display {label: "Create Multipart Upload"}
    remote isolated function createMultipartUpload(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            *MultipartUploadConfig config) 
            returns @display {label: "Upload ID"} string|Error {
        return check nativeCreateMultipartUpload(self, bucketName, objectKey, config);
    }

    # Uploads a part in a multipart upload.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + uploadId - The upload ID from createMultipartUpload
    # + partNumber - The part number (1-10000)
    # + content - The part content (string | xml | json | byte[])
    # + config - Optional upload part configuration
    # + return - ETag of the uploaded part or an Error
    @display {label: "Upload Part"}
    remote isolated function uploadPart(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Upload ID"} string uploadId,
            @display {label: "Part Number"} int partNumber,
            @display {label: "Content"} anydata content,
            *UploadPartConfig config)
            returns @display {label: "ETag"} string|Error {
        byte[] converted = toByteArray(content);
        return check nativeUploadPart(self, bucketName, objectKey, uploadId, partNumber, converted, config);
    }

    # Uploads a part from a stream.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + uploadId - The upload ID from createMultipartUpload
    # + partNumber - The part number (1-10000)
    # + contentStream - The content stream
    # + config - Optional upload part configuration
    # + return - ETag of the uploaded part or an Error
    @display {label: "Upload Part As Stream"}
    remote isolated function uploadPartAsStream(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Upload ID"} string uploadId,
            @display {label: "Part Number"} int partNumber,
            @display {label: "Content Stream"} stream<byte[], error?> contentStream,
            *UploadPartConfig config)
            returns @display {label: "ETag"} string|Error {
        return check nativeUploadPartWithStream(self, bucketName, objectKey, uploadId, partNumber, contentStream, config);
    }

    # Completes a multipart upload.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + uploadId - The upload ID from createMultipartUpload
    # + partNumbers - Array of part numbers
    # + etags - Array of ETags corresponding to each part
    # + return - An Error if completion fails
    @display {label: "Complete Multipart Upload"}
    remote isolated function completeMultipartUpload(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Upload ID"} string uploadId,
            @display {label: "Part Numbers"} int[] partNumbers,
            @display {label: "ETags"} string[] etags) returns Error? {
        check nativeCompleteMultipartUpload(self, bucketName, objectKey, uploadId, partNumbers, etags);
    }

    # Aborts a multipart upload.
    #
    # + bucketName - The name of the bucket
    # + objectKey - The path of the object
    # + uploadId - The upload ID from createMultipartUpload
    # + return - An Error if abort fails
    @display {label: "Abort Multipart Upload"}
    remote isolated function abortMultipartUpload(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Upload ID"} string uploadId) returns Error? {
        check nativeAbortMultipartUpload(self, bucketName, objectKey, uploadId);
    }
}

// NATIVE INTEROP DECLARATIONS
isolated function initClient(Client clientObj, ConnectionConfig config) returns Error? = @java:Method {
    name: "initClient",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCreateBucket(Client self, string bucket, CreateBucketConfig config) returns Error? = @java:Method {
    name: "createBucket",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeDeleteBucket(Client self, string bucket) returns Error? = @java:Method {
    name: "deleteBucket",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeListBuckets(Client clientObj) returns json|Error = @java:Method {
    name: "listBuckets",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeGetBucketLocation(Client self, string bucket) returns string|Error = @java:Method {
    name: "getBucketLocation",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativePutObjectFromFile(Client clientObj, string bucket, string key, string filePath, PutObjectConfig config) returns Error? = @java:Method {
    name: "putObjectFromFile",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativePutObjectWithContent(Client clientObj, string bucket, string key, byte[] content, PutObjectConfig config) returns Error? = @java:Method {
    name: "putObjectWithContent",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativePutObjectWithStream(Client clientObj, string bucket, string key, stream<byte[], error?> contentStream, PutObjectConfig config) returns Error? = @java:Method {
    name: "putObjectWithStream",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeGetObject(Client clientObj, string bucket, string key, GetObjectConfig config) returns S3StreamResult|Error = @java:Method {
    name: "getObject",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeDeleteObject(Client clientObj, string bucket, string key, DeleteObjectConfig config) returns Error? = @java:Method {
    name: "deleteObject",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeListObjectsV2(Client self, string bucket, ListObjectsConfig config) returns json|Error = @java:Method {
    name: "listObjectsV2",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeHeadObject(Client self, string bucket, string key, HeadObjectConfig config) returns json|Error = @java:Method {
    name: "headObject",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCopyObject(Client self, string sourceBucket, string sourceKey, string destBucket, string destKey, CopyObjectConfig config) returns Error? = @java:Method {
    name: "copyObject",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCreatePresignedUrl(Client self, string bucket, string key, PresignedUrlConfig config) returns string|Error = @java:Method {
    name: "createPresignedUrl",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;


isolated function nativeDoesObjectExist(Client self, string bucket, string key) returns boolean = @java:Method {
    name: "doesObjectExist",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCreateMultipartUpload(Client self, string bucket, string key, MultipartUploadConfig config) returns string|Error = @java:Method {
    name: "createMultipartUpload",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeUploadPart(Client self, string bucket, string key, string uploadId, int partNumber, byte[] content, UploadPartConfig config) returns string|Error = @java:Method {
    name: "uploadPart",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeUploadPartWithStream(Client self, string bucket, string key, string uploadId, int partNumber, stream<byte[], error?> contentStream, UploadPartConfig config) returns string|Error = @java:Method {
    name: "uploadPartWithStream",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCompleteMultipartUpload(Client self, string bucket, string key, string uploadId, int[] partNumbers, string[] etags) returns Error? = @java:Method {
    name: "completeMultipartUpload",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeAbortMultipartUpload(Client self, string bucket, string key, string uploadId) returns Error? = @java:Method {
    name: "abortMultipartUpload",
    'class: "io.ballerina.lib.aws.s3.NativeClientAdaptor"
} external;
