package org.ballerinax.aws.s3;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.values.BStream;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.utils.StringUtils;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;

import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.waiters.S3Waiter;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.io.InputStream;
import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class NativeClientAdaptor {

    private static final String NATIVE_CLIENT = "NATIVE_S3_CLIENT";
    private static final String NATIVE_CONFIG = "NATIVE_CONNECTION_CONFIG";

    // Client Initialization Method
    @SuppressWarnings("unchecked")
    public static Object initClient(BObject clientObj, BMap<BString, Object> config) {
        try {
            // Region is always at top level ConnectionConfig
            String region = config.getStringValue(StringUtils.fromString("region")).getValue();

            Object authObj = config.get(StringUtils.fromString("auth"));
            if (!(authObj instanceof BMap)) {
                return S3ExceptionUtils.createError("Invalid auth configuration provided");
            }
            BMap<BString, Object> auth = (BMap<BString, Object>) authObj;

            AwsCredentialsProvider credentialsProvider;

            // StaticAuthConfig branch
            if (auth.containsKey(StringUtils.fromString("accessKeyId"))) {
                String accessKeyId = auth.getStringValue(StringUtils.fromString("accessKeyId")).getValue();
                String secretAccessKey = auth.getStringValue(StringUtils.fromString("secretAccessKey")).getValue();
                // sessionToken is currently ignored at SDK level; can be wired separately if
                // needed
                AwsCredentials credentials = AwsBasicCredentials.create(accessKeyId, secretAccessKey);
                credentialsProvider = StaticCredentialsProvider.create(credentials);

                // ProfileAuthConfig branch
            } else if (auth.containsKey(StringUtils.fromString("profileName"))) {
                String profileName = auth.getStringValue(StringUtils.fromString("profileName")).getValue();
                credentialsProvider = ProfileCredentialsProvider.create(profileName);

            } else {
                return S3ExceptionUtils.createError("Unsupported auth configuration");
            }

            S3Client s3Client = S3Client.builder()
                    .region(Region.of(region))
                    .credentialsProvider(credentialsProvider)
                    .build();

            clientObj.addNativeData(NATIVE_CLIENT, s3Client);
            ConnectionConfig connConfig = new ConnectionConfig(Region.of(region), credentialsProvider);
            clientObj.addNativeData(NATIVE_CONFIG, connConfig);
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    private static S3Client getClient(BObject clientObj) {
        S3Client client = (S3Client) clientObj.getNativeData(NATIVE_CLIENT);
        if (client == null) {
            throw S3ExceptionUtils.createError("S3 Client is not initialized");
        }
        return client;
    }

    private static ConnectionConfig getConnectionConfig(BObject clientObj) {
        ConnectionConfig config = (ConnectionConfig) clientObj.getNativeData(NATIVE_CONFIG);
        if (config == null) {
            throw S3ExceptionUtils.createError("S3 Connection Config is not initialized");
        }
        return config;
    }

    // Bucket Operations

    public static Object createBucket(BObject clientObj, BString bucketName, BMap<BString, Object> config) {
        S3Client s3Client = getClient(clientObj);
        String bucket = bucketName.getValue();
        try {
            CreateBucketRequest.Builder builder = CreateBucketRequest.builder().bucket(bucket);

            if (config.containsKey(StringUtils.fromString("acl"))) {
                Object aclObj = config.get(StringUtils.fromString("acl"));
                if (aclObj instanceof BString) {
                    builder.acl(((BString) aclObj).getValue());
                }
            }
            if (config.containsKey(StringUtils.fromString("objectOwnership"))) {
                Object ownershipObj = config.get(StringUtils.fromString("objectOwnership"));
                if (ownershipObj instanceof BString) {
                    builder.objectOwnership(((BString) ownershipObj).getValue());
                }
            }
            if (config.containsKey(StringUtils.fromString("objectLockEnabled"))) {
                Object lockObj = config.get(StringUtils.fromString("objectLockEnabled"));
                if (lockObj instanceof Boolean) {
                    builder.objectLockEnabledForBucket((Boolean) lockObj);
                }
            }

            s3Client.createBucket(builder.build());

            S3Waiter s3Waiter = s3Client.waiter();
            HeadBucketRequest bucketRequestWait = HeadBucketRequest.builder().bucket(bucket).build();
            s3Waiter.waitUntilBucketExists(bucketRequestWait);

            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object deleteBucket(BObject clientObj, BString bucket) {
        S3Client s3 = getClient(clientObj);
        try {
            s3.deleteBucket(DeleteBucketRequest.builder().bucket(bucket.getValue()).build());
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object listBuckets(BObject clientObj) {
        S3Client s3 = getClient(clientObj);
        try {
            List<Bucket> buckets = s3.listBuckets().buckets();
            BString[] bBuckets = new BString[buckets.size()];
            for (int i = 0; i < buckets.size(); i++) {
                bBuckets[i] = StringUtils.fromString(buckets.get(i).name());
            }
            return ValueCreator.createArrayValue(bBuckets);
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object getBucketLocation(BObject clientObj, BString bucket) {
        S3Client s3 = getClient(clientObj);
        try {
            GetBucketLocationRequest request = GetBucketLocationRequest.builder()
                    .bucket(bucket.getValue())
                    .build();
            GetBucketLocationResponse response = s3.getBucketLocation(request);
            String location = response.locationConstraintAsString();
            return StringUtils.fromString(location != null ? location : "us-east-1");
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    // Object Operations

    public static Object putObjectFromFile(BObject clientObj, BString bucket, BString key, BString filePath,
            BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            PutObjectRequest.Builder builder = PutObjectRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue());

            applyPutObjectConfig(builder, config);

            s3.putObject(builder.build(), RequestBody.fromFile(java.nio.file.Paths.get(filePath.getValue())));
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object putObjectWithContent(BObject clientObj, BString bucket, BString key, BArray content,
            BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            PutObjectRequest.Builder builder = PutObjectRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue());

            applyPutObjectConfig(builder, config);

            s3.putObject(builder.build(), RequestBody.fromBytes(content.getBytes()));
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object putObjectWithStream(Environment env, BObject clientObj, BString bucket, BString key, 
            BStream contentStream, BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            PutObjectRequest.Builder builder = PutObjectRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue());
            
            applyPutObjectConfig(builder, config);
            
            // Create an InputStream that reads from the Ballerina stream
            InputStream inputStream = new BallerinaStreamInputStream(env, contentStream);
            
            s3.putObject(builder.build(), RequestBody.fromInputStream(inputStream, inputStream.available()));
            
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    @SuppressWarnings("unchecked")
    private static void applyPutObjectConfig(PutObjectRequest.Builder builder, BMap<BString, Object> config) {
        if (config.containsKey(StringUtils.fromString("contentType"))) {
            Object obj = config.get(StringUtils.fromString("contentType"));
            if (obj instanceof BString)
                builder.contentType(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("acl"))) {
            Object obj = config.get(StringUtils.fromString("acl"));
            if (obj instanceof BString)
                builder.acl(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("storageClass"))) {
            Object obj = config.get(StringUtils.fromString("storageClass"));
            if (obj instanceof BString)
                builder.storageClass(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("cacheControl"))) {
            Object obj = config.get(StringUtils.fromString("cacheControl"));
            if (obj instanceof BString)
                builder.cacheControl(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("contentDisposition"))) {
            Object obj = config.get(StringUtils.fromString("contentDisposition"));
            if (obj instanceof BString)
                builder.contentDisposition(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("contentEncoding"))) {
            Object obj = config.get(StringUtils.fromString("contentEncoding"));
            if (obj instanceof BString)
                builder.contentEncoding(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("contentLanguage"))) {
            Object obj = config.get(StringUtils.fromString("contentLanguage"));
            if (obj instanceof BString)
                builder.contentLanguage(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("tagging"))) {
            Object obj = config.get(StringUtils.fromString("tagging"));
            if (obj instanceof BString)
                builder.tagging(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("serverSideEncryption"))) {
            Object obj = config.get(StringUtils.fromString("serverSideEncryption"));
            if (obj instanceof BString)
                builder.serverSideEncryption(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("metadata"))) {
            Object metaObj = config.get(StringUtils.fromString("metadata"));
            if (metaObj instanceof BMap) {
                BMap<BString, Object> metaMap = (BMap<BString, Object>) metaObj;
                Map<String, String> metadata = new HashMap<>();
                metaMap.entrySet().forEach(entry -> {
                    Object value = entry.getValue();
                    if (value instanceof BString) {
                        metadata.put(entry.getKey().getValue(), ((BString) value).getValue());
                    }
                });
                builder.metadata(metadata);
            }
        }
    }

    public static Object getObject(Environment env, BObject clientObj, BString bucket, BString key,
            BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            GetObjectRequest.Builder builder = GetObjectRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue());

            if (config.containsKey(StringUtils.fromString("versionId"))) {
                Object obj = config.get(StringUtils.fromString("versionId"));
                if (obj instanceof BString)
                    builder.versionId(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("range"))) {
                Object obj = config.get(StringUtils.fromString("range"));
                if (obj instanceof BString)
                    builder.range(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("ifMatch"))) {
                Object obj = config.get(StringUtils.fromString("ifMatch"));
                if (obj instanceof BString)
                    builder.ifMatch(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("ifNoneMatch"))) {
                Object obj = config.get(StringUtils.fromString("ifNoneMatch"));
                if (obj instanceof BString)
                    builder.ifNoneMatch(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("ifModifiedSince"))) {
                Object obj = config.get(StringUtils.fromString("ifModifiedSince"));
                if (obj instanceof BString)
                    builder.ifModifiedSince(Instant.parse(((BString) obj).getValue()));
            }
            if (config.containsKey(StringUtils.fromString("ifUnmodifiedSince"))) {
                Object obj = config.get(StringUtils.fromString("ifUnmodifiedSince"));
                if (obj instanceof BString)
                    builder.ifUnmodifiedSince(Instant.parse(((BString) obj).getValue()));
            }
            if (config.containsKey(StringUtils.fromString("partNumber"))) {
                Object obj = config.get(StringUtils.fromString("partNumber"));
                if (obj instanceof Long)
                    builder.partNumber(((Long) obj).intValue());
            }

            ResponseInputStream<GetObjectResponse> s3Stream = s3.getObject(builder.build());
            BObject streamWrapper = ValueCreator.createObjectValue(env.getCurrentModule(), "S3StreamResult");
            streamWrapper.addNativeData("NATIVE_STREAM", s3Stream);
            return streamWrapper;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object deleteObject(BObject clientObj, BString bucket, BString key, BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            DeleteObjectRequest.Builder builder = DeleteObjectRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue());

            if (config.containsKey(StringUtils.fromString("versionId"))) {
                Object obj = config.get(StringUtils.fromString("versionId"));
                if (obj instanceof BString)
                    builder.versionId(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("mfa"))) {
                Object obj = config.get(StringUtils.fromString("mfa"));
                if (obj instanceof BString)
                    builder.mfa(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("bypassGovernanceRetention"))) {
                Object obj = config.get(StringUtils.fromString("bypassGovernanceRetention"));
                if (obj instanceof Boolean)
                    builder.bypassGovernanceRetention((Boolean) obj);
            }

            s3.deleteObject(builder.build());
            return null;
        } catch (NoSuchKeyException e) {
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    @SuppressWarnings("unchecked")
    public static Object listObjectsV2(BObject clientObj, BString bucket, BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            ListObjectsV2Request.Builder builder = ListObjectsV2Request.builder()
                    .bucket(bucket.getValue());

            if (config.containsKey(StringUtils.fromString("prefix"))) {
                Object obj = config.get(StringUtils.fromString("prefix"));
                if (obj instanceof BString && !((BString) obj).getValue().isEmpty()) {
                    builder.prefix(((BString) obj).getValue());
                }
            }
            if (config.containsKey(StringUtils.fromString("delimiter"))) {
                Object obj = config.get(StringUtils.fromString("delimiter"));
                if (obj instanceof BString && !((BString) obj).getValue().isEmpty()) {
                    builder.delimiter(((BString) obj).getValue());
                }
            }
            if (config.containsKey(StringUtils.fromString("maxKeys"))) {
                Object obj = config.get(StringUtils.fromString("maxKeys"));
                if (obj instanceof Long) {
                    builder.maxKeys(((Long) obj).intValue());
                }
            }
            if (config.containsKey(StringUtils.fromString("continuationToken"))) {
                Object obj = config.get(StringUtils.fromString("continuationToken"));
                if (obj instanceof BString && !((BString) obj).getValue().isEmpty()) {
                    builder.continuationToken(((BString) obj).getValue());
                }
            }
            if (config.containsKey(StringUtils.fromString("startAfter"))) {
                Object obj = config.get(StringUtils.fromString("startAfter"));
                if (obj instanceof BString && !((BString) obj).getValue().isEmpty()) {
                    builder.startAfter(((BString) obj).getValue());
                }
            }
            if (config.containsKey(StringUtils.fromString("fetchOwner"))) {
                Object obj = config.get(StringUtils.fromString("fetchOwner"));
                if (obj instanceof Boolean) {
                    builder.fetchOwner((Boolean) obj);
                }
            }

            ListObjectsV2Response response = s3.listObjectsV2(builder.build());
            BMap<BString, Object> result = ValueCreator.createMapValue();
            List<S3Object> objects = response.contents();
            int size = objects.size();

            // Create array of S3Object maps
            BMap<BString, Object>[] objArray = new BMap[size];
            for (int i = 0; i < size; i++) {
                S3Object obj = objects.get(i);
                BMap<BString, Object> objMap = ValueCreator.createMapValue();

                objMap.put(StringUtils.fromString("key"), StringUtils.fromString(obj.key()));
                objMap.put(StringUtils.fromString("size"), (long) obj.size());
                objMap.put(StringUtils.fromString("lastModified"),
                        StringUtils.fromString(obj.lastModified().toString()));
                objMap.put(StringUtils.fromString("eTag"), StringUtils.fromString(obj.eTag()));
                objMap.put(StringUtils.fromString("storageClass"), StringUtils.fromString(obj.storageClassAsString()));

                objArray[i] = objMap;
            }

            // Convert array to BArray using ValueCreator
            BArray objectsArray = ValueCreator.createArrayValue(objArray,
                    TypeCreator.createArrayType(PredefinedTypes.TYPE_JSON));

            result.put(StringUtils.fromString("objects"), objectsArray);
            result.put(StringUtils.fromString("count"), (long) size);
            result.put(StringUtils.fromString("isTruncated"), response.isTruncated());

            if (response.nextContinuationToken() != null) {
                result.put(StringUtils.fromString("nextContinuationToken"),
                        StringUtils.fromString(response.nextContinuationToken()));
            }

            return result;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object headObject(BObject clientObj, BString bucket, BString key, BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            HeadObjectRequest.Builder builder = HeadObjectRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue());

            if (config.containsKey(StringUtils.fromString("versionId"))) {
                Object obj = config.get(StringUtils.fromString("versionId"));
                if (obj instanceof BString)
                    builder.versionId(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("partNumber"))) {
                Object obj = config.get(StringUtils.fromString("partNumber"));
                if (obj instanceof Long)
                    builder.partNumber(((Long) obj).intValue());
            }

            HeadObjectResponse response = s3.headObject(builder.build());
            BMap<BString, Object> metadata = ValueCreator.createMapValue();

            metadata.put(StringUtils.fromString("key"), key);
            metadata.put(StringUtils.fromString("contentLength"), response.contentLength());
            if (response.contentType() != null) {
                metadata.put(StringUtils.fromString("contentType"), StringUtils.fromString(response.contentType()));
            }
            metadata.put(StringUtils.fromString("eTag"), StringUtils.fromString(response.eTag()));
            metadata.put(StringUtils.fromString("lastModified"),
                    StringUtils.fromString(response.lastModified().toString()));
            metadata.put(StringUtils.fromString("storageClass"),
                    StringUtils.fromString(response.storageClassAsString()));
            if (response.versionId() != null) {
                metadata.put(StringUtils.fromString("versionId"), StringUtils.fromString(response.versionId()));
            }

            if (response.metadata() != null && !response.metadata().isEmpty()) {
                BMap<BString, Object> userMeta = ValueCreator.createMapValue();
                response.metadata()
                        .forEach((k, v) -> userMeta.put(StringUtils.fromString(k), StringUtils.fromString(v)));
                metadata.put(StringUtils.fromString("userMetadata"), userMeta);
            }

            return metadata;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    @SuppressWarnings("unchecked")
    public static Object copyObject(BObject clientObj, BString sourceBucket, BString sourceKey, BString destBucket,
            BString destKey, BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            CopyObjectRequest.Builder builder = CopyObjectRequest.builder()
                    .sourceBucket(sourceBucket.getValue())
                    .sourceKey(sourceKey.getValue())
                    .destinationBucket(destBucket.getValue())
                    .destinationKey(destKey.getValue());

            if (config.containsKey(StringUtils.fromString("acl"))) {
                Object obj = config.get(StringUtils.fromString("acl"));
                if (obj instanceof BString)
                    builder.acl(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("storageClass"))) {
                Object obj = config.get(StringUtils.fromString("storageClass"));
                if (obj instanceof BString)
                    builder.storageClass(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("metadataDirective"))) {
                Object obj = config.get(StringUtils.fromString("metadataDirective"));
                if (obj instanceof BString)
                    builder.metadataDirective(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("contentType"))) {
                Object obj = config.get(StringUtils.fromString("contentType"));
                if (obj instanceof BString)
                    builder.contentType(((BString) obj).getValue());
            }
            if (config.containsKey(StringUtils.fromString("metadata"))) {
                Object metaObj = config.get(StringUtils.fromString("metadata"));
                if (metaObj instanceof BMap) {
                    BMap<BString, Object> metaMap = (BMap<BString, Object>) metaObj;
                    Map<String, String> metadata = new HashMap<>();
                    metaMap.entrySet().forEach(entry -> {
                        Object value = entry.getValue();
                        if (value instanceof BString) {
                            metadata.put(entry.getKey().getValue(), ((BString) value).getValue());
                        }
                    });
                    builder.metadata(metadata);
                }
            }

            s3.copyObject(builder.build());
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static boolean doesObjectExist(BObject clientObj, BString bucket, BString key) {
        S3Client s3 = getClient(clientObj);
        try {
            HeadObjectRequest request = HeadObjectRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue())
                    .build();
            s3.headObject(request);
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (Exception e) {
            throw S3ExceptionUtils.createError(e);
        }
    }

    // Multipart Upload Operations

    public static Object createMultipartUpload(BObject clientObj, BString bucket, BString key,
            BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            CreateMultipartUploadRequest.Builder builder = CreateMultipartUploadRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue());

            applyMultipartConfig(builder, config);

            CreateMultipartUploadResponse response = s3.createMultipartUpload(builder.build());
            return StringUtils.fromString(response.uploadId());
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    @SuppressWarnings("unchecked")
    private static void applyMultipartConfig(CreateMultipartUploadRequest.Builder builder,
            BMap<BString, Object> config) {
        if (config.containsKey(StringUtils.fromString("contentType"))) {
            Object obj = config.get(StringUtils.fromString("contentType"));
            if (obj instanceof BString)
                builder.contentType(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("acl"))) {
            Object obj = config.get(StringUtils.fromString("acl"));
            if (obj instanceof BString)
                builder.acl(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("storageClass"))) {
            Object obj = config.get(StringUtils.fromString("storageClass"));
            if (obj instanceof BString)
                builder.storageClass(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("tagging"))) {
            Object obj = config.get(StringUtils.fromString("tagging"));
            if (obj instanceof BString)
                builder.tagging(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("serverSideEncryption"))) {
            Object obj = config.get(StringUtils.fromString("serverSideEncryption"));
            if (obj instanceof BString)
                builder.serverSideEncryption(((BString) obj).getValue());
        }
        if (config.containsKey(StringUtils.fromString("metadata"))) {
            Object metaObj = config.get(StringUtils.fromString("metadata"));
            if (metaObj instanceof BMap) {
                BMap<BString, Object> metaMap = (BMap<BString, Object>) metaObj;
                Map<String, String> metadata = new HashMap<>();
                metaMap.entrySet().forEach(entry -> {
                    Object value = entry.getValue();
                    if (value instanceof BString) {
                        metadata.put(entry.getKey().getValue(), ((BString) value).getValue());
                    }
                });
                builder.metadata(metadata);
            }
        }
    }

    public static Object uploadPart(BObject clientObj, BString bucket, BString key, BString uploadId,
            long partNumber, BArray content, BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            byte[] contentBytes = content.getBytes();

            UploadPartRequest.Builder builder = UploadPartRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue())
                    .uploadId(uploadId.getValue())
                    .partNumber((int) partNumber);

            // Apply optional config parameters
            if (config != null) {
                if (config.containsKey(StringUtils.fromString("contentLength"))) {
                    Object lengthObj = config.get(StringUtils.fromString("contentLength"));
                    if (lengthObj instanceof Long) {
                        builder.contentLength(((Long) lengthObj));
                    }
                }
                if (config.containsKey(StringUtils.fromString("contentMD5"))) {
                    Object md5Obj = config.get(StringUtils.fromString("contentMD5"));
                    if (md5Obj instanceof BString) {
                        builder.contentMD5(((BString) md5Obj).getValue());
                    }
                }
            }

            UploadPartRequest request = builder.build();
            UploadPartResponse response = s3.uploadPart(request, RequestBody.fromBytes(contentBytes));

            return StringUtils.fromString(response.eTag());
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object uploadPartWithStream(Environment env, BObject clientObj, BString bucket, BString key, 
            BString uploadId, long partNumber, BStream contentStream, BMap<BString, Object> config) {
        S3Client s3 = getClient(clientObj);
        try {
            UploadPartRequest.Builder builder = UploadPartRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue())
                    .uploadId(uploadId.getValue())
                    .partNumber((int) partNumber);
            
            if (config.containsKey(StringUtils.fromString("contentLength"))) {
                Object obj = config.get(StringUtils.fromString("contentLength"));
                if (obj instanceof Long) {
                    builder.contentLength((Long) obj);
                }
            }
            
            if (config.containsKey(StringUtils.fromString("contentMD5"))) {
                Object obj = config.get(StringUtils.fromString("contentMD5"));
                if (obj instanceof BString) {
                    builder.contentMD5(((BString) obj).getValue());
                }
            }
            
            // Create an InputStream that reads from the Ballerina stream
            InputStream inputStream = new BallerinaStreamInputStream(env, contentStream);
            
            UploadPartResponse response = s3.uploadPart(builder.build(), 
                    RequestBody.fromInputStream(inputStream, inputStream.available()));
            
            return StringUtils.fromString(response.eTag());
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object completeMultipartUpload(BObject clientObj, BString bucket, BString key, BString uploadId,
            BArray partNumbers, BArray etags) {
        S3Client s3 = getClient(clientObj);
        try {
            List<CompletedPart> parts = new ArrayList<>();
            long[] pNums = partNumbers.getIntArray();
            String[] eTagsStr = etags.getStringArray();

            for (int i = 0; i < pNums.length; i++) {
                parts.add(CompletedPart.builder()
                        .partNumber((int) pNums[i])
                        .eTag(eTagsStr[i])
                        .build());
            }

            CompletedMultipartUpload completedMultipartUpload = CompletedMultipartUpload.builder()
                    .parts(parts)
                    .build();

            CompleteMultipartUploadRequest request = CompleteMultipartUploadRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue())
                    .uploadId(uploadId.getValue())
                    .multipartUpload(completedMultipartUpload)
                    .build();

            s3.completeMultipartUpload(request);
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    public static Object abortMultipartUpload(BObject clientObj, BString bucket, BString key, BString uploadId) {
        S3Client s3 = getClient(clientObj);
        try {
            AbortMultipartUploadRequest request = AbortMultipartUploadRequest.builder()
                    .bucket(bucket.getValue())
                    .key(key.getValue())
                    .uploadId(uploadId.getValue())
                    .build();

            s3.abortMultipartUpload(request);
            return null;
        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    // Presigned URL Operations

    public static Object createPresignedUrl(BObject clientObj, BString bucket, BString key,
            BMap<BString, Object> config) {
        try {
            long expirationMinutes = 15;
            if (config.containsKey(StringUtils.fromString("expirationMinutes"))) {
                expirationMinutes = config.getIntValue(StringUtils.fromString("expirationMinutes"));
            }

            String httpMethod = "GET";
            if (config.containsKey(StringUtils.fromString("httpMethod"))) {
                Object methodObj = config.get(StringUtils.fromString("httpMethod"));
                if (methodObj instanceof BString) {
                    httpMethod = ((BString) methodObj).getValue().toUpperCase();
                }
            }

            ConnectionConfig connConfig = getConnectionConfig(clientObj);

            S3Presigner presigner = S3Presigner.builder()
                    .region(connConfig.region)
                    .credentialsProvider(connConfig.credentialsProvider)
                    .build();

            String presignedUrl;

            switch (httpMethod) {
                case "GET":
                    presignedUrl = generateGetPresignedUrl(presigner, bucket.getValue(), key.getValue(),
                            expirationMinutes, config);
                    break;
                case "PUT":
                    presignedUrl = generatePutPresignedUrl(presigner, bucket.getValue(), key.getValue(),
                            expirationMinutes, config);
                    break;
                default:
                    presigner.close();
                    return S3ExceptionUtils.createError(new IllegalArgumentException(
                            "Unsupported HTTP method: " + httpMethod + ". Supported methods: GET, PUT"));
            }

            presigner.close();
            return StringUtils.fromString(presignedUrl);

        } catch (Exception e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    private static String generateGetPresignedUrl(S3Presigner presigner, String bucket, String key,
            long expirationMinutes, BMap<BString, Object> config) {

        GetObjectRequest.Builder getBuilder = GetObjectRequest.builder()
                .bucket(bucket)
                .key(key);

        if (config.containsKey(StringUtils.fromString("versionId"))) {
            Object versionObj = config.get(StringUtils.fromString("versionId"));
            if (versionObj instanceof BString) {
                getBuilder.versionId(((BString) versionObj).getValue());
            }
        }
        if (config.containsKey(StringUtils.fromString("responseContentType"))) {
            Object contentTypeObj = config.get(StringUtils.fromString("responseContentType"));
            if (contentTypeObj instanceof BString) {
                getBuilder.responseContentType(((BString) contentTypeObj).getValue());
            }
        }
        if (config.containsKey(StringUtils.fromString("contentDisposition"))) {
            Object dispositionObj = config.get(StringUtils.fromString("contentDisposition"));
            if (dispositionObj instanceof BString) {
                getBuilder.responseContentDisposition(((BString) dispositionObj).getValue());
            }
        }

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(expirationMinutes))
                .getObjectRequest(getBuilder.build())
                .build();

        PresignedGetObjectRequest presignedRequest = presigner.presignGetObject(presignRequest);
        return presignedRequest.url().toString();
    }

    private static String generatePutPresignedUrl(S3Presigner presigner, String bucket, String key,
            long expirationMinutes, BMap<BString, Object> config) {

        PutObjectRequest.Builder putBuilder = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key);

        if (config.containsKey(StringUtils.fromString("contentType"))) {
            Object contentTypeObj = config.get(StringUtils.fromString("contentType"));
            if (contentTypeObj instanceof BString) {
                putBuilder.contentType(((BString) contentTypeObj).getValue());
            }
        }
        if (config.containsKey(StringUtils.fromString("contentDisposition"))) {
            Object dispositionObj = config.get(StringUtils.fromString("contentDisposition"));
            if (dispositionObj instanceof BString) {
                putBuilder.contentDisposition(((BString) dispositionObj).getValue());
            }
        }

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(expirationMinutes))
                .putObjectRequest(putBuilder.build())
                .build();

        PresignedPutObjectRequest presignedRequest = presigner.presignPutObject(presignRequest);
        return presignedRequest.url().toString();
    }

    // Stream Operations
    @SuppressWarnings("unchecked")
    public static Object readStreamBytes(BObject streamWrapper) {
        ResponseInputStream<GetObjectResponse> input = (ResponseInputStream<GetObjectResponse>) streamWrapper
                .getNativeData("NATIVE_STREAM");
        if (input == null)
            return S3ExceptionUtils.createError("Stream is closed.");

        try {
            byte[] buffer = new byte[4096];
            int read = input.read(buffer);
            if (read == -1) {
                input.close();
                return null;
            }
            if (read < 4096) {
                byte[] trimmed = new byte[read];
                System.arraycopy(buffer, 0, trimmed, 0, read);
                return ValueCreator.createArrayValue(trimmed);
            }
            return ValueCreator.createArrayValue(buffer);
        } catch (IOException e) {
            return S3ExceptionUtils.createError(e);
        }
    }

    // Inner Class
    public static class ConnectionConfig {
        public final Region region;
        public final AwsCredentialsProvider credentialsProvider;

        public ConnectionConfig(Region region, AwsCredentialsProvider credentialsProvider) {
            this.region = region;
            this.credentialsProvider = credentialsProvider;
        }
    }

    // Helper class to convert Ballerina stream to Java InputStream
    private static class BallerinaStreamInputStream extends InputStream {
        private static final String BAL_STREAM_CLOSE = "close";
        private static final String STREAM_VALUE = "value";
        private static final String BAL_STREAM_NEXT = "next";
        
        private final Environment environment;
        private final BStream ballerinaStream;
        private byte[] currentChunk;
        private int chunkPosition;
        private boolean endOfStream;
        private final boolean hasCloseMethod;

        public BallerinaStreamInputStream(Environment environment, BStream ballerinaStream) {
            this.ballerinaStream = ballerinaStream;
            this.environment = environment;
            this.currentChunk = null;
            this.chunkPosition = 0;
            this.endOfStream = false;
            
            // Check if stream has a close method
            Type iteratorType = ballerinaStream.getIteratorObj().getOriginalType();
            if (iteratorType instanceof ObjectType) {
                ObjectType iteratorObjectType = (ObjectType) iteratorType;
                MethodType[] methods = iteratorObjectType.getMethods();
                hasCloseMethod = java.util.Arrays.stream(methods)
                        .anyMatch(method -> method.getName().equals(BAL_STREAM_CLOSE));
            } else {
                hasCloseMethod = false;
            }
        }

        @Override
        public int read() throws IOException {
            if (endOfStream) {
                return -1;
            }

            // If no current chunk or exhausted, fetch next
            if (currentChunk == null || chunkPosition >= currentChunk.length) {
                if (!fetchNextChunk()) {
                    endOfStream = true;
                    return -1;
                }
            }

            return currentChunk[chunkPosition++] & 0xFF;
        }

        @Override
        public int read(byte[] b, int off, int len) throws IOException {
            if (endOfStream) {
                return -1;
            }
            if (b == null) {
                throw new NullPointerException();
            } else if (off < 0 || len < 0 || len > b.length - off) {
                throw new IndexOutOfBoundsException();
            } else if (len == 0) {
                return 0;
            }

            int totalRead = 0;
            while (totalRead < len) {
                // Fetch next chunk if needed
                if (currentChunk == null || chunkPosition >= currentChunk.length) {
                    if (!fetchNextChunk()) {
                        endOfStream = true;
                        return totalRead == 0 ? -1 : totalRead;
                    }
                }

                // Copy from current chunk
                int available = currentChunk.length - chunkPosition;
                int toRead = Math.min(available, len - totalRead);
                System.arraycopy(currentChunk, chunkPosition, b, off + totalRead, toRead);
                chunkPosition += toRead;
                totalRead += toRead;
            }

            return totalRead;
        }

        private boolean fetchNextChunk() throws IOException {
            try {
                // Call next() method on the stream using Ballerina runtime
                Object result = environment.getRuntime().callMethod(
                        ballerinaStream.getIteratorObj(), BAL_STREAM_NEXT, null);
                
                if (result instanceof BError) {
                    throw new IOException("Error reading from stream: " + ((BError) result).getMessage());
                }
                
                if (result == null) {
                    return false;
                }
                
                if (result instanceof BMap) {
                    BMap<?, ?> record = (BMap<?, ?>) result;
                    Object value = record.get(StringUtils.fromString(STREAM_VALUE));
                    
                    if (value instanceof BArray) {
                        currentChunk = ((BArray) value).getBytes();
                        chunkPosition = 0;
                        return currentChunk.length > 0;
                    } else {
                        throw new IOException("Unexpected value type in stream");
                    }
                } else {
                    throw new IOException("Unexpected result type from stream.next()");
                }
            } catch (Exception e) {
                throw new IOException("Error reading from Ballerina stream: " + e.getMessage(), e);
            }
        }

        @Override
        public void close() throws IOException {
            if (!hasCloseMethod) {
                return;
            }
            
            Object result = environment.getRuntime().callMethod(
                    ballerinaStream.getIteratorObj(), BAL_STREAM_CLOSE, null);
            
            if (result instanceof BError) {
                throw new IOException(((BError) result).getMessage());
            }
            
            endOfStream = true;
            currentChunk = null;
        }
    }


}
