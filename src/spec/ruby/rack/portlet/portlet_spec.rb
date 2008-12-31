require File.dirname(__FILE__) + '/../../spec_helper'

import org.jruby.rack.portlet.RackPortlet
import javax.portlet.PortletMode
import java.util.HashMap

describe RackPortlet do

  before :each do
    @request_dispatcher = mock("Portlet Request Dispatcher")
    @request_dispatcher.stub!(:include)

    @portlet_context = mock("Portlet Context")
    @portlet_context.stub!(:getRequestDispatcher).and_return @request_dispatcher

    @portlet_config = mock("Portlet Config")
    @portlet_config.stub!(:getInitParameter).and_return nil
    @portlet_config.stub!(:getPortletContext).and_return @portlet_context

    @view_mode = PortletMode.new('view')

    @portlet_request = mock("Portlet Request", :null_object => true)
    @portlet_request.stub!(:getPortletMode).and_return @view_mode
    @portlet_response = mock("Portlet Response")

    @portlet = RackPortlet.new(@portlet_config)
  end

  it 'should build the default request path' do
    path = @portlet.buildRequestPath(@portlet_request, @portlet_config)
    path.should == '/portlet/view'
  end

  it 'should use a custom action path' do
    @portlet_config.stub!(:getInitParameter).with('view.path').and_return '/custom_view'

    path = @portlet.buildRequestPath(@portlet_request, @portlet_config)
    path.should == '/portlet/custom_view'
  end

  it 'should use a custom root path' do
    @portlet_config.stub!(:getInitParameter).with('root.path').and_return '/custom_root'

    path = @portlet.buildRequestPath(@portlet_request, @portlet_config)
    path.should == '/custom_root/view'
  end

  it 'should build an action path' do
    @portlet_request.stub!(:getAttribute).with('portlet.action').and_return true

    path = @portlet.buildRequestPath(@portlet_request, @portlet_config)
    path.should == '/portlet/action'
  end

  it 'should build an event path' do
    @portlet_request.stub!(:getAttribute).with('portlet.event').and_return true

    path = @portlet.buildRequestPath(@portlet_request, @portlet_config)
    path.should == '/portlet/event'
  end

  it 'should build a query string' do
    params = HashMap.new
    bar = java.lang.String[1].new
    bar[0] = 'bar'
    params['foo'] = bar
    @portlet_request.stub!(:getPrivateParameterMap).and_return params

    query = @portlet.buildQueryString(@portlet_request)
    query.should == 'foo=bar&'
  end

end