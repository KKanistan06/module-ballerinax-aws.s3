import ballerina/jballerina.java;
import ballerina/io;

# The AWS S3 Client Connector
@display {label: "AWS S3 Client", iconPath: "icon.png"}
public isolated client class Client {

    # Initializes the S3 Client
    #
    # + config - The connection configuration
    # + return - An Error if initialization fails
    public isolated function init(*ConnectionConfig config) returns Error? {
        return initClient(self, config);
    }

    # Creates an S3 bucket
    #
    # + bucketName - The name of the bucket
    # + config - Optional bucket configuration
    # + return - An Error if bucket creation fails
    @display {label: "Create Bucket"}
    remote isolated function createBucket(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Bucket Configuration"} CreateBucketConfig config = {}) returns Error? {
        error? result = nativeCreateBucket(self, bucketName, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }

    # Deletes an S3 bucket
    #
    # + bucketName - The name of the bucket
    # + return - An Error if bucket deletion fails
    @display {label: "Delete Bucket"}
    remote isolated function deleteBucket(@display {label: "Bucket Name"} string bucketName) returns Error? {
        error? result = nativeDeleteBucket(self, bucketName);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }

    # Lists all buckets in the AWS account
    #
    # + return - List of buckets or an Error
    @display {label: "List Buckets"}
    remote isolated function listBuckets() returns @display {label: "Bucket Names"} Bucket[]|Error {
        any|error result = nativeListBuckets(self);
        if result is error {
            return error Error(result.message(), result);
        }
        return <Bucket[]>result;
    }

    # Gets the AWS region of a bucket
    #
    # + bucketName - The name of the bucket
    # + return - Region string or an Error
    @display {label: "Get Bucket Location"}
    remote isolated function getBucketLocation(@display {label: "Bucket Name"} string bucketName) 
            returns @display {label: "Region"} string|Error {
        string|error result = nativeGetBucketLocation(self, bucketName);
        if result is error {
            return error Error(result.message(), result);
        }
        return result;
    }

    # Uploads an object from a file path
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
    # + filePath - The local file path to upload
    # + config - Optional upload configuration
    # + return - An Error if the upload fails
    @display {label: "Put Object From File"}
    remote isolated function putObjectFromFile(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "File Path"} string filePath,
            @display {label: "Upload Configuration"} PutObjectConfig config = {}) returns Error? {
        error? result = nativePutObjectFromFile(self, bucketName, objectKey, filePath, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }

    # Uploads an object from content
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
    # + content - The object content (string | xml | json | byte[])
    # + config - Optional upload configuration
    # + return - An Error if the upload fails
    @display {label: "Put Object"}
    remote isolated function putObject(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Content"} ObjectContent content,
            @display {label: "Upload Configuration"} PutObjectConfig config = {}) returns Error? {
        
        byte[]|Error converted = toByteArray(content);
        if converted is Error {
            return converted;
        }
        
        error? result = nativePutObjectWithContent(self, bucketName, objectKey, converted, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }

    # Uploads an object from a stream (memory efficient for large files)
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
    # + contentStream - The content stream
    # + config - Optional upload configuration
    # + return - An Error if the upload fails
    @display {label: "Put Object As Stream"}
    remote isolated function putObjectAsStream(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Content Stream"} stream<byte[], io:Error?> contentStream,
            @display {label: "Upload Configuration"} PutObjectConfig config = {}) returns Error? {
        
        error? result = nativePutObjectWithStream(self, bucketName, objectKey, contentStream, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }



    # Downloads an object from S3 as a stream
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
    # + config - Optional retrieval configuration
    # + return - A stream of byte chunks, or an Error
    @display {label: "Get Object"}
    remote isolated function getObject(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Retrieval Configuration"} GetObjectConfig config = {}) 
            returns @display {label: "Byte Stream"} stream<byte[], Error?>|Error {
        S3StreamResult|error streamImpl = nativeGetObject(self, bucketName, objectKey, config);
        if streamImpl is error {
            return error Error(streamImpl.message(), streamImpl);
        }
        return new stream<byte[], Error?>(streamImpl);
    }

    # Deletes an object from S3
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key of the object to delete
    # + config - Optional deletion configuration
    # + return - An Error if deletion fails
    @display {label: "Delete Object"}
    remote isolated function deleteObject(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Deletion Configuration"} DeleteObjectConfig config = {}) returns Error? {
        error? result = nativeDeleteObject(self, bucketName, objectKey, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }

    # Lists objects in a bucket
    #
    # + bucketName - The name of the bucket
    # + config - Optional listing configuration
    # + return - List of objects or an Error
    @display {label: "List Objects"}
    remote isolated function listObjects(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Listing Configuration"} ListObjectsConfig config = {})
            returns @display {label: "Objects List"} ListObjectsResponse|Error {
        any|error result = nativeListObjectsV2(self, bucketName, config);
        if result is error {
            return error Error(result.message(), result);
        }

        // Convert to ListObjectsResponse
        if result is map<anydata> {
            ListObjectsResponse|error converted = result.cloneWithType(ListObjectsResponse);
            if converted is error {
                return error Error("Failed to parse list objects response", converted);
            }
            return converted;
        }
        
        return error Error("Invalid response type from native method");
    }

    # Creates a presigned URL for temporary access to an S3 object
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key of the object
    # + config - Optional presigned URL configuration
    # + return - Presigned URL string or an Error
    @display {label: "Create Presigned URL"}
    remote isolated function createPresignedUrl(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Presigned URL Configuration"} PresignedUrlConfig config = {}) 
            returns @display {label: "Presigned URL"} string|Error {
        any|error result = nativeCreatePresignedUrl(self, bucketName, objectKey, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return <string>result;
    }

    # Gets metadata for an object without downloading it
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key of the object
    # + config - Optional metadata retrieval configuration
    # + return - Object metadata or an Error
    @display {label: "Get Object Metadata"}
    remote isolated function getObjectMetadata(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Metadata Configuration"} HeadObjectConfig config = {}) 
            returns @display {label: "Metadata"} ObjectMetadata|Error {
        any|error result = nativeHeadObject(self, bucketName, objectKey, config);
        if result is error {
            return error Error(result.message(), result);
        }
        
        // Direct cast instead of type check
        map<anydata> resultMap = <map<anydata>>result;
        ObjectMetadata|error converted = resultMap.cloneWithType(ObjectMetadata);
        if converted is error {
            return error Error("Failed to parse object metadata", converted);
        }
        return converted;
    }

    # Copies an object from one location to another
    #
    # + sourceBucket - Source bucket name
    # + sourceKey - Source object key
    # + destinationBucket - Destination bucket name
    # + destinationKey - Destination object key
    # + config - Optional copy configuration
    # + return - An Error if copy fails
    @display {label: "Copy Object"}
    remote isolated function copyObject(@display {label: "Source Bucket"} string sourceBucket,
            @display {label: "Source Key"} string sourceKey,
            @display {label: "Destination Bucket"} string destinationBucket,
            @display {label: "Destination Key"} string destinationKey,
            @display {label: "Copy Configuration"} CopyObjectConfig config = {}) returns Error? {
        error? result = nativeCopyObject(self, sourceBucket, sourceKey, destinationBucket, destinationKey, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }

    # Checks if an object exists in a bucket
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key of the object
    # + return - True if exists, false otherwise
    @display {label: "Does Object Exist"}
    remote isolated function doesObjectExist(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey) 
            returns @display {label: "Exists"} boolean {
        return nativeDoesObjectExist(self, bucketName, objectKey);
    }

    # Creates a multipart upload
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
    # + config - Optional multipart upload configuration
    # + return - Upload ID or an Error
    @display {label: "Create Multipart Upload"}
    remote isolated function createMultipartUpload(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Upload Configuration"} MultipartUploadConfig config = {}) 
            returns @display {label: "Upload ID"} string|Error {
        any|error result = nativeCreateMultipartUpload(self, bucketName, objectKey, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return <string>result;
    }

    # Uploads a part in a multipart upload
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
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
            @display {label: "Content"} ObjectContent content,
            @display {label: "Upload Part Config"} UploadPartConfig config = {})
            returns @display {label: "ETag"} string|Error {
        
        byte[]|Error converted = toByteArray(content);
        if converted is Error {
            return converted;
        }
        
        any|error result = nativeUploadPart(self, bucketName, objectKey, uploadId, partNumber, converted, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return <string>result;  // Add explicit cast
    }


    # Uploads a part from a stream (memory efficient for large parts)
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
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
            @display {label: "Content Stream"} stream<byte[], io:Error?> contentStream,
            @display {label: "Upload Part Config"} UploadPartConfig config = {})
            returns @display {label: "ETag"} string|Error {
        
        any|error result = nativeUploadPartWithStream(self, bucketName, objectKey, uploadId, partNumber, contentStream, config);
        if result is error {
            return error Error(result.message(), result);
        }
        return <string>result;  // Add explicit cast here
    }



    # Completes a multipart upload
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
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
        error? result = nativeCompleteMultipartUpload(self, bucketName, objectKey, uploadId, partNumbers, etags);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }

    # Aborts a multipart upload
    #
    # + bucketName - The name of the bucket
    # + objectKey - The key (path) of the object
    # + uploadId - The upload ID from createMultipartUpload
    # + return - An Error if abort fails
    @display {label: "Abort Multipart Upload"}
    remote isolated function abortMultipartUpload(@display {label: "Bucket Name"} string bucketName,
            @display {label: "Object Key"} string objectKey,
            @display {label: "Upload ID"} string uploadId) returns Error? {
        error? result = nativeAbortMultipartUpload(self, bucketName, objectKey, uploadId);
        if result is error {
            return error Error(result.message(), result);
        }
        return;
    }
}



// NATIVE INTEROP DECLARATIONS
isolated function initClient(Client clientObj, ConnectionConfig config) returns Error? = @java:Method {
    name: "initClient",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCreateBucket(Client self, string bucket, CreateBucketConfig config) returns error? = @java:Method {
    name: "createBucket",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeDeleteBucket(Client self, string bucket) returns error? = @java:Method {
    name: "deleteBucket",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeListBuckets(Client clientObj) returns any|error = @java:Method {
    name: "listBuckets",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeGetBucketLocation(Client self, string bucket) returns string|error = @java:Method {
    name: "getBucketLocation",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativePutObjectFromFile(Client clientObj, string bucket, string key, string filePath, PutObjectConfig config) returns error? = @java:Method {
    name: "putObjectFromFile",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativePutObjectWithContent(Client clientObj, string bucket, string key, byte[] content, PutObjectConfig config) returns error? = @java:Method {
    name: "putObjectWithContent",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativePutObjectWithStream(Client clientObj, string bucket, string key, stream<byte[], io:Error?> contentStream, PutObjectConfig config) returns error? = @java:Method {
    name: "putObjectWithStream",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeGetObject(Client clientObj, string bucket, string key, GetObjectConfig config) returns S3StreamResult|error = @java:Method {
    name: "getObject",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeDeleteObject(Client clientObj, string bucket, string key, DeleteObjectConfig config) returns error? = @java:Method {
    name: "deleteObject",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeListObjectsV2(Client self, string bucket, ListObjectsConfig config) returns any|error = @java:Method {
    name: "listObjectsV2",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeHeadObject(Client self, string bucket, string key, HeadObjectConfig config) returns any|error = @java:Method {
    name: "headObject",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCopyObject(Client self, string sourceBucket, string sourceKey, string destBucket, string destKey, CopyObjectConfig config) returns error? = @java:Method {
    name: "copyObject",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCreatePresignedUrl(Client self, string bucket, string key, PresignedUrlConfig config) returns any|error = @java:Method {
    name: "createPresignedUrl",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;


isolated function nativeDoesObjectExist(Client self, string bucket, string key) returns boolean = @java:Method {
    name: "doesObjectExist",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCreateMultipartUpload(Client self, string bucket, string key, MultipartUploadConfig config) returns any|error = @java:Method {
    name: "createMultipartUpload",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeUploadPart(Client self, string bucket, string key, string uploadId, int partNumber, byte[] content, UploadPartConfig config) returns any|error = @java:Method {
    name: "uploadPart",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeUploadPartWithStream(Client self, string bucket, string key, string uploadId, int partNumber, stream<byte[], io:Error?> contentStream, UploadPartConfig config) returns string|error = @java:Method {
    name: "uploadPartWithStream",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeCompleteMultipartUpload(Client self, string bucket, string key, string uploadId, int[] partNumbers, string[] etags) returns error? = @java:Method {
    name: "completeMultipartUpload",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

isolated function nativeAbortMultipartUpload(Client self, string bucket, string key, string uploadId) returns error? = @java:Method {
    name: "abortMultipartUpload",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;
