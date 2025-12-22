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
