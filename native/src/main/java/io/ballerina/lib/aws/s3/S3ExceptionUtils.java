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

package io.ballerina.lib.aws.s3;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BError;
import software.amazon.awssdk.services.s3.model.S3Exception;

/**
 * Utility class for creating Ballerina errors from the aws.s3 module.
 */
public class S3ExceptionUtils {

    private static Module s3Module;

    /**
     * Initialize the module reference. Should be called during client initialization.
     */
    public static void initModule(Environment env) {
        s3Module = env.getCurrentModule();
    }

    /**
     * Creates a Ballerina Error of type `ballerinax/aws.s3:Error`.
     *
     * @param message The error message
     * @return BError instance of module's Error type
     */
    public static BError createError(String message) {
        if (s3Module != null) {
            return ErrorCreator.createError(s3Module, "Error", 
                    StringUtils.fromString(message), null, null);
        }
        // Fallback if module not initialized
        return ErrorCreator.createError(StringUtils.fromString(message));
    }

    /**
     * Creates a Ballerina Error of type `ballerinax/aws.s3:Error` with a cause.
     *
     * @param message The error message
     * @param cause   The cause error
     * @return BError instance of module's Error type
     */
    public static BError createError(String message, BError cause) {
        if (s3Module != null) {
            return ErrorCreator.createError(s3Module, "Error", 
                    StringUtils.fromString(message), cause, null);
        }
        return ErrorCreator.createError(StringUtils.fromString(message), cause);
    }

    /**
     * Creates a Ballerina Error from a Throwable.
     *
     * @param t The throwable
     * @return BError instance of module's Error type
     */
    public static BError createError(Throwable t) {
        String message;
        if (t instanceof S3Exception) {
            S3Exception s3Ex = (S3Exception) t;
            String errorMessage = s3Ex.awsErrorDetails() != null ? 
                s3Ex.awsErrorDetails().errorMessage() : s3Ex.getMessage();
            message = errorMessage != null ? errorMessage : s3Ex.getMessage();
        } else {
            message = t.getMessage() != null ? t.getMessage() : t.getClass().getSimpleName();
        }
        return createError(message);
    }
}
