public type Error distinct error;

public type S3Error distinct Error;

public type NoSuchKeyError distinct S3Error;

public type BucketAlreadyExistsError distinct S3Error;

public type ClientError distinct Error;