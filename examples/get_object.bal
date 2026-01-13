import ballerina/io;
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

public function main() returns error? {
    stream<byte[], error?>|error getObjectResponse = amazonS3Client->getObjectAsStream(bucketName, "test.txt");
    if getObjectResponse is error {
        log:printError("Error occurred while getting object", getObjectResponse);
    } else {
        check getObjectResponse.forEach(function(byte[] res) {
            error? writeRes = io:fileWriteBytes("./resources/test.txt", res, io:APPEND);
            if writeRes is error {
                log:printError("Error occurred while writing object", writeRes);
            }
        });
    }
}
