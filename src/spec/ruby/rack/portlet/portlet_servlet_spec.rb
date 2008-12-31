require File.dirname(__FILE__) + '/../../spec_helper'

import org.jruby.rack.portlet.RackPortletServlet

describe RackPortletServlet, "service" do
  before :each do
    @request = javax.servlet.http.HttpServletRequest.impl {}
    @response = javax.servlet.http.HttpServletResponse.impl {}
    @dispatcher = mock("dispatcher", :null_object => true)
    @servlet = RackPortletServlet.new(@dispatcher)
  end

  it 'should pass through non-portlet request' do
    @servlet.should_not_receive(:modifyRequest)
    @servlet.service @request, @response
  end

  it 'should modify portlet request' do
    @request.stub!(:getAttribute).with('portlet.request').and_return "I'm not null"
    @request.stub!(:getAttribute).with('portlet.request.path').and_return "/some/path"
    @request.stub!(:getAttribute).with('portlet.request.query').and_return "hi=there"
    @dispatcher.should_receive(:process).ordered.and_return do |request, response|
      request.getRequestURI.should == '/some/path?hi=there'
    end
    @servlet.service @request, @response
  end

end
