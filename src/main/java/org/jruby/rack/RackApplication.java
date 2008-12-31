/*
 * Copyright 2007-2008 Sun Microsystems, Inc.
 * This source code is available under the MIT license.
 * See the file LICENSE.txt for details.
 */

package org.jruby.rack;

import org.jruby.Ruby;

/**
 * Application object that encapsulates the JRuby runtime and the
 * entry point to the web application.
 * @author nicksieger
 */
public interface RackApplication {
    void init() throws RackInitializationException;
    void destroy();

    /** Make a request into the Rack-based Ruby web application. */
    public RackResponse call(RackEnvironment env);

    /**
     * Get a reference to the underlying runtime that holds the application
     * and supporting code. Useful for embedding environments that wish to access
     * the application without entering through the web request/response cycle.
     */
    Ruby getRuntime();
}
