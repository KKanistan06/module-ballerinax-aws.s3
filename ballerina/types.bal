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

# Static credential configuration
public type StaticAuthConfig record {|
    # The AWS Access Key ID
    string accessKeyId;
    # The AWS Secret Access Key
    string secretAccessKey;
    # Optional session token for temporary credentials
    string sessionToken?;
|};

# Profile-based credential configuration 
public type ProfileAuthConfig record {|
    # AWS shared credentials profile name
    string profileName = "default";
    # Path to the credentials file
    string credentialsFilePath = "~/.aws/credentials";
|};

# Authentication configuration
public type AuthConfig StaticAuthConfig|ProfileAuthConfig;

# Configuration for the AWS S3 Client.
public type ConnectionConfig record {|
    # Authentication configuration
    AuthConfig auth;
    # The AWS Region
    string region;
|};


# Configuration for creating a bucket.
public type CreateBucketConfig record {|
    # Who can access the bucket (e.g., "private", "public-read")
    CannedACL acl = PRIVATE;
    # Who owns objects uploaded to this bucket (e.g., "BucketOwnerEnforced", "ObjectWriter")
    ObjectOwnership objectOwnership = BUCKET_OWNER_ENFORCED;
    # Enable Object Lock to prevent objects from being deleted or overwritten
    boolean objectLockEnabled?;
|};

# Defines bucket.
public type Bucket record {
    # The name of the bucket
    string name;
    # The creation date of the bucket
    string creationDate;
    # The AWS region of the bucket
    string region;
};

# Represents byte array type for getObject return type.
public type Bytes byte[];

# Represents xml type for getObject return type.
public type Xml xml;

# Configuration for uploading an object.
public type PutObjectConfig record {|
    # The file type (e.g., "image/jpeg", "application/pdf", "text/plain")
    string contentType?;
    # Who can access this object (e.g., "private", "public-read")
    CannedACL acl = PRIVATE;
    # Storage type (e.g., "STANDARD", "GLACIER" for archive, "INTELLIGENT_TIERING")
    StorageClass storageClass = STANDARD;
    # Custom data to attach to the object (e.g., {"author": "John", "project": "demo"})
    map<string> metadata?;
    # How long to cache the file (e.g., "max-age=3600" for 1 hour)
    string cacheControl?;
    # How to handle download (e.g., "attachment; filename=report.pdf")
    string contentDisposition?;
    # Compression type (e.g., "gzip")
    string contentEncoding?;
    # Language of the content (e.g., "en-US", "fr")
    string contentLanguage?;
    # When the object expires
    string expires?;
    # Tags for the object (e.g., "env=prod&team=finance")
    string tagging?;
    # Encryption type ("AES256" or "aws:kms")
    string serverSideEncryption?;
|};

# Configuration for retrieving an object.
public type GetObjectConfig record {|
    # Get a specific version of the object (when versioning is enabled)
    string versionId?;
    # Download only part of the file (e.g., "bytes=0-1023" for first 1KB)
    string range?;
    # Only download if the file's ID matches this value
    string ifMatch?;
    # Only download if the file's ID does NOT match this value
    string ifNoneMatch?;
    # Only download if the file was changed after this date (e.g., "2024-01-15T00:00:00Z")
    string ifModifiedSince?;
    # Only download if the file was NOT changed after this date (e.g., "2024-01-15T00:00:00Z")
    string ifUnmodifiedSince?;
    # For multipart uploads, which part number to get (starts at 1)
    int partNumber?;
    # Override the file type in the response (e.g., "text/plain")
    string responseContentType?;
    # Override how the file is downloaded (e.g., "attachment; filename=myfile.pdf")
    string responseContentDisposition?;
|};

# Configuration for deleting an object.
public type DeleteObjectConfig record {|
    # Delete a specific version of the object (when versioning is enabled)
    string versionId?;
    # Multi-factor authentication token (needed if MFA Delete is turned on for the bucket)
    string mfa?;
    # Skip the lock protection and delete the object even if it's protected (use with caution)
    boolean bypassGovernanceRetention?;
|};

# Configuration for listing objects.
public type ListObjectsConfig record {|
    # Filter objects that start with this value (e.g., "photos/" for all objects in photos folder)
    string prefix?;
    # Character to group object keys (e.g., "/" to list like folders)
    string delimiter?;
    # Maximum number of objects to return (1-1000)
    int maxKeys?;
    # Token to get the next page of results
    string continuationToken?;
    # List objects after this key name
    string startAfter?;
    # Include owner info in the results
    boolean fetchOwner?;
    # Encoding type for object keys (e.g., "url")
    string encodingType?;
|};

# Configuration for copying an object.
public type CopyObjectConfig record {|
    # Who can access the copied object (e.g., "private", "public-read")
    CannedACL acl = PRIVATE;
    # Storage type for the copied object (e.g., "STANDARD", "GLACIER")
    StorageClass storageClass = STANDARD;
    # "COPY" to keep original metadata or "REPLACE" to use new metadata
    string metadataDirective?;
    # New metadata for the copied object (only used when metadataDirective is "REPLACE")
    map<string> metadata?;
    # File type for the copied object (e.g., "image/jpeg")
    string contentType?;
    # How long to cache the file (e.g., "max-age=3600")
    string cacheControl?;
    # How to handle download (e.g., "attachment; filename=report.pdf")
    string contentDisposition?;
    # Compression type (e.g., "gzip")
    string contentEncoding?;
    # Tags for the copied object (e.g., "env=prod&team=finance")
    string tagging?;
    # Only copy if source file's ETag matches this value
    string copySourceIfMatch?;
    # Only copy if source file's ETag does NOT match this value
    string copySourceIfNoneMatch?;
    # Only copy if source file changed after this date
    string copySourceIfModifiedSince?;
    # Only copy if source file has NOT changed after this date
    string copySourceIfUnmodifiedSince?;
|};

# Configuration for getting object metadata.
public type HeadObjectConfig record {|
    # Get metadata for a specific version of the object (when versioning is enabled)
    string versionId?;
    # For multipart uploads, which part number to get metadata for (starts at 1) 
    int partNumber?;
    # Only get metadata if the file's ETag matches this value
    string ifMatch?;
    # Only get metadata if the file's ETag does NOT match this value
    string ifNoneMatch?;
    # Only get metadata if the file changed after this date
    string ifModifiedSince?;
    # Only get metadata if the file has NOT changed after this date
    string ifUnmodifiedSince?;
|};

# Configuration for creating presigned URLs.
public type PresignedUrlConfig record {|
    # How long the URL is valid in minutes (default: 15, max: 10080 for 7 days)
    int expirationMinutes = 15;
    # What action the URL allows ("GET" to download, "PUT" to upload)
    string httpMethod = "GET";
    # File type for upload URLs (e.g., "image/jpeg")
    string contentType?;
    # How to handle download (e.g., "attachment; filename=report.pdf")
    string contentDisposition?;
    # Override file type when downloading (e.g., "text/plain")
    string responseContentType?;
    # Get URL for a specific version of the object (when versioning is enabled)
    string versionId?;
|};

# Configuration for multipart upload (for large files uploaded in parts).
public type MultipartUploadConfig record {|
    # File type (e.g., "image/jpeg", "application/pdf")
    string contentType?;
    # Who can access this object (e.g., "private", "public-read")
    CannedACL acl = PRIVATE;
    # Storage type (e.g., "STANDARD", "GLACIER" for archive)
    StorageClass storageClass = STANDARD;
    # Custom data to attach to the object (e.g., {"author": "John"})
    map<string> metadata?;
    # How long to cache the file (e.g., "max-age=3600")
    string cacheControl?;
    # How to handle download (e.g., "attachment; filename=report.pdf")
    string contentDisposition?;
    # Compression type (e.g., "gzip")
    string contentEncoding?;
    # Tags for the object (e.g., "env=prod&team=finance")
    string tagging?;
    # Encryption type ("AES256" or "aws:kms")
    string serverSideEncryption?;
|};

# Configuration for uploading a single part in a multipart upload.
public type UploadPartConfig record {|
    # Size of the part in bytes
    int contentLength?;
    # MD5 hash of the part content (for data integrity check)
    string contentMD5?;
|};

# Represents a single S3 object in a listing.
public type S3Object record {|
    # The object's path/name in the bucket (e.g., "photos/image.jpg")
    string key;
    # Size of the object in bytes
    int size;
    # When the object was last changed
    string lastModified;
    # Unique ID of the object's content
    string eTag;
    # Storage type (e.g., "STANDARD", "GLACIER")
    StorageClass storageClass = STANDARD;
|};

# Response from listing objects in a bucket.
public type ListObjectsResponse record {|
    # List of objects found
    S3Object[] objects;
    # Number of objects returned
    int count;
    # True if there are more results (use nextContinuationToken to get them)
    boolean isTruncated;
    # Token to get the next page of results
    string nextContinuationToken?;
|};

# Metadata information about an S3 object.
public type ObjectMetadata record {|
    # The object's path/name in the bucket (e.g., "photos/image.jpg")
    string key;
    # Size of the object in bytes
    int contentLength;
    # File type (e.g., "image/jpeg", "application/pdf")
    string contentType?;
    # Unique ID of the object's content 
    string eTag;
    # When the object was last changed 
    string lastModified;
    # Storage type (e.g., "STANDARD", "GLACIER")
    StorageClass storageClass = STANDARD;
    # Version ID of the object (when versioning is enabled)
    string versionId?;
    # Custom data attached to the object
    map<anydata> userMetadata?;
|};

# Basic information about an S3 object.
public type ObjectInfo record {|
    # The object's path/name in the bucket (e.g., "photos/image.jpg")
    string key;
    # Size of the object in bytes
    int size;
    # When the object was last changed
    string lastModified;
    # Unique ID of the object's content
    string eTag;
    # Storage type (e.g., "STANDARD", "GLACIER")
    StorageClass storageClass = STANDARD;
|};

# Access control options for buckets and objects.
public enum CannedACL {
    # Only the owner has access
    PRIVATE = "private",
    # Anyone can read
    PUBLIC_READ = "public-read",
    # Anyone can read and write
    PUBLIC_READ_WRITE = "public-read-write",
    # Only authenticated AWS users can read
    AUTHENTICATED_READ = "authenticated-read",
    # EC2 gets read access to GET the object
    AWS_EXEC_READ = "aws-exec-read",
    # Bucket owner can read
    BUCKET_OWNER_READ = "bucket-owner-read",
    # Bucket owner has full control
    BUCKET_OWNER_FULL_CONTROL = "bucket-owner-full-control"
}

# Who owns objects uploaded to the bucket.
public enum ObjectOwnership {
    # Bucket owner owns all objects (recommended, ACLs disabled)
    BUCKET_OWNER_ENFORCED = "BucketOwnerEnforced",
    # The uploader owns the object
    OBJECT_WRITER = "ObjectWriter",
    # Bucket owner owns if uploader grants full control
    BUCKET_OWNER_PREFERRED = "BucketOwnerPreferred"
}

# Storage options for S3 objects (affects cost and access speed).
public enum StorageClass {
    # Default storage for frequently accessed data
    STANDARD = "STANDARD",
    # Lower cost for less critical, reproducible data
    REDUCED_REDUNDANCY = "REDUCED_REDUNDANCY",
    # Lower cost for infrequently accessed data (min 30 days)
    STANDARD_IA = "STANDARD_IA",
    # Lower cost, single availability zone (min 30 days)
    ONEZONE_IA = "ONEZONE_IA",
    # Auto-moves data between tiers based on access patterns
    INTELLIGENT_TIERING = "INTELLIGENT_TIERING",
    # Low cost archive, retrieval takes minutes to hours
    GLACIER = "GLACIER",
    # Archive with instant retrieval (min 90 days)
    GLACIER_IR = "GLACIER_IR",
    # Lowest cost archive, retrieval takes hours (min 180 days)
    DEEP_ARCHIVE = "DEEP_ARCHIVE"
}
