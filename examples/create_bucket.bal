import ballerina/log;
import ballerinax/aws.s3;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = ?;
configurable string bucketName = ?;

s3:ConnectionConfig amazonS3Config = {
    auth: {
        accessKeyId,
        secretAccessKey
    },
    region
};

final s3:Client amazonS3Client = check new (amazonS3Config);

public function main() {
    error? createBucketResponse = amazonS3Client->createBucket(bucketName, acl = s3:PRIVATE);
    if createBucketResponse is error {
        log:printError("Error: " + createBucketResponse.toString());
    } else {
        log:printInfo("Bucket Creation Status: Success");
    }
}
