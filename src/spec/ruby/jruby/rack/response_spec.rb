#--
# Copyright 2007-2008 Sun Microsystems, Inc.
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

require File.dirname(__FILE__) + '/../../spec_helper'
require 'jruby/rack/response'

describe JRuby::Rack::Response do
  before :each do
    @status, @headers, @body = mock("status"), mock("headers"), mock("body")
    @headers.stub!(:[]).and_return nil
    @servlet_response = mock "servlet response"
    @response = JRuby::Rack::Response.new([@status, @headers, @body])
  end

  it "should return the status, headers and body" do
    @response.getStatus.should == @status
    @response.getHeaders.should == @headers
    @body.should_receive(:each).and_yield "hello"
    @response.getBody.should == "hello"
  end

  it "should write the status to the servlet response" do
    @status.should_receive(:to_i).and_return(200)
    @servlet_response.should_receive(:setStatus).with(200)
    @response.write_status(@servlet_response)
  end

  it "should write the headers to the servlet response" do
    @headers.should_receive(:each).and_return do |block|
      block.call "Content-Type", "text/html"
      block.call "Content-Length", "20"
      block.call "Server",  "Apache/2.2.x"
    end
    @servlet_response.should_receive(:setContentType).with("text/html")
    @servlet_response.should_receive(:setContentLength).with(20)
    @servlet_response.should_receive(:addHeader).with("Server", "Apache/2.2.x")
    @response.write_headers(@servlet_response)
  end

  it "should write headers with multiple values multiple addHeader invocations" do
    @headers.should_receive(:each).and_return do |block|
      block.call "Content-Type", "text/html"
      block.call "Content-Length", "20"
      block.call "Set-Cookie",  %w(cookie1 cookie2)
    end
    @servlet_response.should_receive(:setContentType).with("text/html")
    @servlet_response.should_receive(:setContentLength).with(20)
    @servlet_response.should_receive(:addHeader).with("Set-Cookie", "cookie1")
    @servlet_response.should_receive(:addHeader).with("Set-Cookie", "cookie2")
    @response.write_headers(@servlet_response)
  end

  it "should call addIntHeader with integer value" do
    @headers.should_receive(:each).and_return do |block|
      block.call "Expires", 0
    end
    @servlet_response.should_receive(:addIntHeader).with("Expires", 0)
    @response.write_headers(@servlet_response)
  end

  it "should call addDateHeader with date value" do
    time = Time.now - 1000
    @headers.should_receive(:each).and_return do |block|
      block.call "Last-Modified", time
    end
    @servlet_response.should_receive(:addDateHeader).with("Last-Modified", time.to_i * 1000)
    @response.write_headers(@servlet_response)
  end

  it "should write the body to the servlet response" do
    @body.should_receive(:each).and_return do |block|
      block.call "hello"
      block.call "there"
    end
    stream = mock "output stream"
    @servlet_response.stub!(:getOutputStream).and_return stream
    stream.should_receive(:write).exactly(2).times

    @response.write_body(@servlet_response)
  end

  it "should write the status first, followed by the headers, and the body last" do
    @response.should_receive(:write_status).ordered
    @response.should_receive(:write_headers).ordered
    @response.should_receive(:write_body).ordered
    @response.respond(@servlet_response)
  end

  it "should forward the request if the special 'Forward' header is present" do
    response = nil
    @headers.should_receive(:[]).with("Forward").and_return(proc {|resp| response = resp})
    @response.respond(@servlet_response)
    response.should == @servlet_response
  end
end
