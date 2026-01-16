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
