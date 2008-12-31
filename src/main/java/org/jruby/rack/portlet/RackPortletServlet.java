package org.jruby.rack.portlet;

import org.jruby.rack.*;
import java.io.IOException;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletInputStream;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpServletResponse;

/**
 *
 * @author masonjm
 */
public class RackPortletServlet extends HttpServlet {
    private RackDispatcher dispatcher;

    /** Default constructor, used by servlet container
     */
    public RackPortletServlet() {
    }

    /** Constructor for testing
     */
    public RackPortletServlet(RackDispatcher dispatcher) {
        this.dispatcher = dispatcher;
    }

    @Override
    public void init(ServletConfig config) {
        this.dispatcher = new DefaultRackDispatcher(config.getServletContext());
    }

    @Override
    public void service(ServletRequest request, ServletResponse response)
        throws ServletException, IOException {
        if (request.getAttribute(RackPortlet.PORTLET_REQUEST) != null) {
            request = modifyRequest((HttpServletRequest) request);
        }
        dispatcher.process((HttpServletRequest) request, (HttpServletResponse) response);
    }

    /**
     * Use request attributes set by the RackPortlet to create a fake request that
     * a Rack application can understand.
     * @param request the odd HttpServletRequest created by the portlet container
     * @return a normal-looking wrapped HttpServletRequest
     */
    protected HttpServletRequest modifyRequest(HttpServletRequest request) {
        return new HttpServletRequestWrapper(request) {
            @Override
            public String getRequestURI() {
                StringBuffer uri = new StringBuffer(this.getPathInfo());
                if (this.getQueryString().length() > 0) {
                    uri.append("?").append(this.getQueryString());
                }
                return uri.toString();
            }
            @Override
            public String getPathInfo() {
                return (String)this.getRequest().getAttribute(RackPortlet.PORTLET_REQUEST_PATH);
            }
            @Override
            public String getQueryString() {
                return (String)this.getRequest().getAttribute(RackPortlet.PORTLET_REQUEST_QUERY);
            }
            @Override public String getServletPath() { return ""; }
            @Override public ServletInputStream getInputStream() { return new EmptyServletInputStream(); }
        };
    }

    /*
     * The ServletRequest created by Liferay's PortletRequestDispatcher#include
     * implementation has null InputStream. This causes DefaultRackApplication#call
     * to choke when it tries to create a RubyIO instance with the stream. This
     * wrapper replaces the null stream with an empty one.
     */
    private class EmptyServletInputStream extends ServletInputStream {
        @Override
        public int read() throws IOException {
            return -1;
        }
    }

}
