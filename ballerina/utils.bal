# Validates if a bucket name follows AWS naming conventions.
#
# + bucketName - The name of the bucket
# + return - True if valid, False otherwise
public isolated function isValidBucketName(string bucketName) returns boolean {
    // 1. Length check (3-63 chars)
    if bucketName.length() < 3 || bucketName.length() > 63 {
        return false;
    }
    
    // 2. Regex check: Lowercase letters, numbers, hyphens, and dots only.
    // Must start and end with a letter or number.
    // (Simplified regex for demonstration)
    string:RegExp bucketPattern = re `^[a-z0-9][a-z0-9-.]*[a-z0-9]$`;
    return bucketPattern.isFullMatch(bucketName);
}

# Utility to convert common error messages to user-friendly text.
# 
# + err - The error returned from the client
# + return - A cleaned up string message
public isolated function getErrorMessage(Error err) returns string {
    return err.message();
}

# Converts various ObjectContent types to a byte array.
# 
# + content - The ObjectContent to convert
# + return - The byte array representation or an Error
public isolated function toByteArray(ObjectContent content) returns byte[]|Error {
    if content is byte[] {
        return content;
    } else if content is string {
        return content.toBytes();
    } else if content is xml {
        return content.toString().toBytes();
    } else if content is json {
        return content.toString().toBytes();
    }
    return error Error("Unsupported content type");
}
