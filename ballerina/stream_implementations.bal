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
        return (); 
    }
}

// Links to the Java static method: S3Operations.readStreamBytes(BObject)
isolated function nativeReadStreamBytes(S3StreamResult streamObj) returns byte[]|Error? = @java:Method {
    name: "readStreamBytes",
    'class: "org.ballerinax.aws.s3.NativeClientAdaptor"
} external;