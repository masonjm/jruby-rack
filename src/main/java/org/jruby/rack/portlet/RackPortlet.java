package org.jruby.rack.portlet;

import java.io.IOException;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Map;
import javax.portlet.ActionRequest;
import javax.portlet.ActionResponse;
import javax.portlet.EventRequest;
import javax.portlet.EventResponse;
import javax.portlet.GenericPortlet;
import javax.portlet.PortletConfig;
import javax.portlet.PortletException;
import javax.portlet.PortletMode;
import javax.portlet.PortletRequest;
import javax.portlet.PortletRequestDispatcher;
import javax.portlet.PortletResponse;
import javax.portlet.RenderRequest;
import javax.portlet.RenderResponse;

/**
 * 
 * @author masonjm
 */
public class RackPortlet extends GenericPortlet {
    public static String ROOT_PATH_KEY = "root.path";
    public static String DEFAULT_ROOT_PATH = "/portlet";

    public static String PORTLET_REQUEST = "portlet.request";
    public static String PORTLET_RESPONSE = "portlet.response";
    public static String PORTLET_CONFIG = "portlet.config";
    public static String PORTLET_ACTION = "portlet.action";
    public static String PORTLET_EVENT = "portlet.event";
    public static String PORTLET_REQUEST_PATH = "portlet.request.path";
    public static String PORTLET_REQUEST_QUERY = "portlet.request.query";
    
    private PortletConfig config;

    /** Empty constructor for Portlet Container instantiation
     */
    public RackPortlet() {}

    /** Constructor for testing
     * @param portletConfigForTesting
     */
    public RackPortlet(PortletConfig portletConfigForTesting) {
        this.config = portletConfigForTesting;
    }

	@Override
	public void init(PortletConfig portletConfig) throws PortletException {
        this.config = portletConfig;
        super.init(portletConfig);
    }

    @Override
    public PortletConfig getPortletConfig() {
        return config;
    }

	@Override
	public void processAction(ActionRequest request, ActionResponse response)
			throws PortletException, IOException {
		request.setAttribute(PORTLET_ACTION, Boolean.TRUE);
        dispatchToRack(request, response);
	}

    @Override
    public void processEvent(EventRequest request, EventResponse response) throws PortletException, IOException {
		request.setAttribute(PORTLET_EVENT, Boolean.TRUE);
        dispatchToRack(request, response);
    }

    @Override
    public void render(RenderRequest request, RenderResponse response) throws PortletException, IOException {
        dispatchToRack(request, response);
    }

    /** Configures the request and passes it on to the RackPortletServlet
     * 
     * @param request
     * @param response
     * @throws javax.portlet.PortletException
     * @throws java.io.IOException
     */
	protected void dispatchToRack(PortletRequest request, PortletResponse response)
			throws PortletException, IOException {
        request.setAttribute(PORTLET_REQUEST, request);
        request.setAttribute(PORTLET_RESPONSE, response);
        request.setAttribute(PORTLET_CONFIG, config);

        request.setAttribute(PORTLET_REQUEST_PATH, buildRequestPath(request, config));
        request.setAttribute(PORTLET_REQUEST_QUERY, buildQueryString(request));

        PortletRequestDispatcher dispatcher = config.getPortletContext().getRequestDispatcher("/org.jruby.rack.portlet.RackPortletServlet");
        dispatcher.include(request, response);
	}

    protected String buildRequestPath(PortletRequest request, PortletConfig config) {
        String rootPath = config.getInitParameter(ROOT_PATH_KEY);
        if (rootPath == null) {
            rootPath = DEFAULT_ROOT_PATH;
        }
        String action = "view";
        if (Boolean.TRUE.equals(request.getAttribute(PORTLET_ACTION))) {
            action = "action";
        } else if (Boolean.TRUE.equals(request.getAttribute(PORTLET_EVENT))) {
            action = "event";
        } else {
            PortletMode mode = request.getPortletMode();
            action = mode.toString();
        }

        String actionPath = config.getInitParameter(action + ".path");
        if (actionPath == null) {
            actionPath = "/" + action;
        }

        return rootPath + actionPath;
    }

    protected String buildQueryString(PortletRequest request) {
        StringBuffer queryString = new StringBuffer();
        try {
            Map<String, String[]> parameters = request.getPrivateParameterMap();
            for (String name: parameters.keySet()) {
                for (String value: parameters.get(name)) {
                        queryString.append(URLEncoder.encode(name, "UTF-8"))
                                .append("=")
                                .append(URLEncoder.encode(value, "UTF-8"))
                                .append("&");
                }
            }
        } catch (UnsupportedEncodingException ex) {
            config.getPortletContext().log("Error building query string", ex);
        }
        return queryString.toString();
    }

}
