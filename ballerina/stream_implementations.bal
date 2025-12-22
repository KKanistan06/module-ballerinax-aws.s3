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

# The iterator class that fetches bytes from the native Java Input Stream.
public isolated class S3StreamResult {

    # Fetches the next chunk of data from the S3 Response Stream.
    #
    # + return - A record containing the byte array, an Error, or nil if the stream ends
    public isolated function next() returns record {| byte[] value; |}|Error? {
        byte[]|Error? result = nativeReadStreamBytes(self);

        if result is byte[] {
            return { value: result };
        } else if result is Error {
            return result;
        }
        return ();
    }

    # Closes the underlying Java Stream to release network resources.
    #
    # + return - An Error if closing fails
    public isolated function close() returns Error? { 
        return nativeCloseStream(self);
    }
}

// Links to the Java static method: NativeClientAdaptor.readStreamBytes(BObject)
isolated function nativeReadStreamBytes(S3StreamResult streamObj) returns byte[]|Error? = @java:Method {
    name: "readStreamBytes",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;

// Links to the Java static method: NativeClientAdaptor.closeStream(BObject)
isolated function nativeCloseStream(S3StreamResult streamObj) returns Error? = @java:Method {
    name: "closeStream",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;