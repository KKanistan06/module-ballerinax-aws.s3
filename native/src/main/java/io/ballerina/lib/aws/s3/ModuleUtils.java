package io.ballerina.lib.aws.s3;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;

/**
 * Module utils for the Ballerina AWS S3 Client to obtain and store the module info during
 * Ballerina module initialization. This avoids extracting module info per-client.
 */
public final class ModuleUtils {
    private static Module module;

    private ModuleUtils() {
    }

    public static Module getModule() {
        return module;
    }

    public static void setModule(Environment environment) {
        module = environment.getCurrentModule();
    }
}
