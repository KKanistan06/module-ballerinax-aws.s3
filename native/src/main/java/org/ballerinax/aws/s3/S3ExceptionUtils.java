package org.ballerinax.aws.s3;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import software.amazon.awssdk.services.s3.model.S3Exception;

public class S3ExceptionUtils {

    public static final String S3_ERROR_PREFIX = "{ballerinax/aws.s3}";

    public static BError createError(String message) {
        return ErrorCreator.createError(
            StringUtils.fromString(S3_ERROR_PREFIX + "Error"),
            StringUtils.fromString(message)
        );
    }

    public static BError createError(Throwable t) {
        if (t instanceof S3Exception) {
            S3Exception s3Ex = (S3Exception) t;
            String errorCode = s3Ex.awsErrorDetails().errorCode();
            String message = s3Ex.awsErrorDetails().errorMessage();
            
            return ErrorCreator.createError(
                StringUtils.fromString(S3_ERROR_PREFIX + errorCode),
                StringUtils.fromString(message != null ? message : s3Ex.getMessage())
            );
        }
        return createError(t.getMessage());
    }
}