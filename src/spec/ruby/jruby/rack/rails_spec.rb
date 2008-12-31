#--
# Copyright 2007-2008 Sun Microsystems, Inc.
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

require File.dirname(__FILE__) + '/../../spec_helper'
require 'jruby/rack/rails'
require 'jruby/rack/rails_ext'
require 'cgi/session/java_servlet_store'
class ::CGI::Session::PStore; end

describe JRuby::Rack::RailsServletHelper do
  before :each do
    @rack_context.stub!(:getInitParameter).and_return nil
    @rack_context.stub!(:getRealPath).and_return "/"
  end

  def create_helper
    @helper = JRuby::Rack::RailsServletHelper.new @rack_context
  end
  
  it "should determine RAILS_ROOT from the 'rails.root' init parameter" do
    @rack_context.should_receive(:getInitParameter).with("rails.root").and_return "/WEB-INF"
    @rack_context.should_receive(:getRealPath).with("/WEB-INF").and_return "./WEB-INF"
    create_helper
    @helper.app_path.should == "./WEB-INF"
  end

  it "should default RAILS_ROOT to /WEB-INF" do
    @rack_context.should_receive(:getRealPath).with("/WEB-INF").and_return "./WEB-INF"
    create_helper
    @helper.app_path.should == "./WEB-INF"
  end

  it "should determine RAILS_ENV from the 'rails.env' init parameter" do
    @rack_context.should_receive(:getInitParameter).with("rails.env").and_return "test"
    create_helper
    @helper.rails_env.should == "test"
  end

  it "should default RAILS_ENV to 'production'" do
    create_helper
    @helper.rails_env.should == "production"
  end

  it "should determine the public html root from the 'public.root' init parameter" do
    @rack_context.should_receive(:getInitParameter).with("public.root").and_return "/blah"
    @rack_context.should_receive(:getRealPath).with("/blah").and_return "."
    create_helper
    @helper.public_path.should == "."
  end

  it "should default public root to '/WEB-INF/public'" do
    @rack_context.should_receive(:getRealPath).with("/WEB-INF").and_return "."
    create_helper
    @helper.public_path.should == "./public"
  end

  it "should create a log device that writes messages to the servlet context" do
    create_helper
    @rack_context.should_receive(:log).with(/hello/)
    @helper.logdev.write "hello"
  end

  it "should setup java servlet-based sessions if the session store is the default" do
    create_helper
    @helper.session_options[:database_manager] = ::CGI::Session::PStore
    @helper.setup_sessions
    @helper.session_options[:database_manager].should == ::CGI::Session::JavaServletStore
  end

  it "should turn off Ruby CGI cookies if the java servlet store is used" do
    create_helper
    @helper.session_options[:database_manager] = ::CGI::Session::JavaServletStore
    @helper.setup_sessions
    @helper.session_options[:no_cookies].should == true
  end

  it "should provide the servlet request in the session options if the java servlet store is used" do
    create_helper
    @helper.session_options[:database_manager] = ::CGI::Session::JavaServletStore
    @helper.setup_sessions
    env = {"java.servlet_request" => mock("servlet request")}
    @helper.session_options_for_request(env).should have_key(:java_servlet_request)
    @helper.session_options_for_request(env)[:java_servlet_request].should == env["java.servlet_request"]
  end

  it "should set the PUBLIC_ROOT constant to the location of the public root" do
    create_helper
    PUBLIC_ROOT.should == @helper.public_path
  end

  describe "#load_environment" do
    before :all do
      mock_servlet_context
      $servlet_context = @servlet_context
      @servlet_context.stub!(:getInitParameter).and_return nil
      @servlet_context.stub!(:getRealPath).and_return "/"
      @helper = JRuby::Rack::RailsServletHelper.new @servlet_context
      @helper.app_path = File.dirname(__FILE__) + "/../../rails"
      @helper.load_environment
    end

    after :all do
      $servlet_context = nil
    end

    it "should default the page cache directory to the public root" do
      ActionController::Base.page_cache_directory.should == @helper.public_path
    end

    it "should default the session store to the java servlet session store" do
      ActionController::Base.session_store.should == CGI::Session::JavaServletStore
    end

    it "should set the ActionView ASSETS_DIR constant to the public root" do
      ActionView::Helpers::AssetTagHelper::ASSETS_DIR.should == @helper.public_path
    end

    it "should set the ActionView JAVASCRIPTS_DIR constant to the public root/javascripts" do
      ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR.should == @helper.public_path + "/javascripts"
    end

    it "should set the ActionView STYLESHEETS_DIR constant to the public root/stylesheets" do
      ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR.should == @helper.public_path + "/stylesheets"
    end
  end
end

describe JRuby::Rack, "Rails controller extensions" do
  before :each do
    @controller = ActionController::Base.new
    @controller.stub!(:request).and_return(request = mock("request"))
    @controller.stub!(:response).and_return(response = mock("response"))
    request.stub!(:env).and_return({"java.servlet_request" => (@servlet_request = mock("servlet request"))})
    @headers = {}
    response.stub!(:headers).and_return @headers
  end

  it "should add a #servlet_request method to ActionController::Base" do
    @controller.should respond_to(:servlet_request)
    @controller.servlet_request.should == @servlet_request
  end

  it "should add a #forward_to method for forwarding to another servlet" do
    @servlet_response = mock "servlet response"
    dispatcher = mock "dispatcher"
    @servlet_request.should_receive(:getRequestDispatcher).with("/forward.jsp").and_return dispatcher
    dispatcher.should_receive(:forward).with(@servlet_request, @servlet_response)

    @controller.forward_to "/forward.jsp"
    @controller.response.headers['Forward'].call(@servlet_response)
  end
end

describe JRuby::Rack::RailsRequestSetup do
  before :each do
    @app = mock "app"
    @servlet_request = mock "servlet request"
    @servlet_request.stub!(:getContextPath).and_return "/blah"
    @helper = mock "servlet helper"
    @options = mock "options"
    @helper.stub!(:session_options_for_request).and_return @options
    @rs = JRuby::Rack::RailsRequestSetup.new @app, @helper
    @env = {}
    @env['java.servlet_request'] = @servlet_request
  end

  it "should set up the env hash for Rails" do
    @app.should_receive(:call).with(@env)
    @rs.call(@env)
    @env['rails.session_options'].should == @options
  end

  it "should set env['HTTPS'] == 'on' if env['rack.url_scheme] == 'https'" do
    @app.should_receive(:call).with(@env)
    @env['rack.url_scheme'] = 'https'
    @rs.call(@env)
    @env['HTTPS'].should == 'on'
  end
end
