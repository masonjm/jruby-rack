require File.dirname(__FILE__) + '/../../spec_helper'

require 'jruby/rack/merb'
import org.jruby.rack.merb.MerbRackApplicationFactory

describe JRuby::Rack::MerbServletHelper do
  before :each do
    @rack_context.stub!(:getRealPath).and_return "/"
  end

  def create_helper
    @helper = JRuby::Rack::MerbServletHelper.new @rack_context
  end

  it "should determine app_path from the 'merb.root' init parameter" do
    @rack_context.should_receive(:getInitParameter).with("merb.root").and_return "/WEB-INF"
    @rack_context.should_receive(:getRealPath).with("/WEB-INF").and_return "./WEB-INF"
    create_helper
    @helper.app_path.should == "./WEB-INF"
  end

  it "should default app_path to /WEB-INF" do
    @rack_context.should_receive(:getRealPath).with("/WEB-INF").and_return "./WEB-INF"
    create_helper
    @helper.app_path.should == "./WEB-INF"
  end

  it "should determine merb_environment from the 'merb.environment' init parameter" do
    @rack_context.should_receive(:getInitParameter).with("merb.environment").and_return "test"
    create_helper
    @helper.merb_environment.should == "test"
  end

  it "should default merb_environment to 'production'" do
    create_helper
    @helper.merb_environment.should == "production"
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

  it "should create a Logger that writes messages to the servlet context" do
    create_helper
    @rack_context.should_receive(:log).with(/hello/)
    @helper.logger.info "hello"
  end

end

describe MerbRackApplicationFactory, "getApplication" do
  it "should load the Merb environment and return an application" do
    @app_factory = MerbRackApplicationFactory.new
    @app_path = File.expand_path(File.dirname(__FILE__) + '/../../merb')
    @rack_context.stub!(:getRealPath).and_return Dir.pwd
    @rack_context.should_receive(:getInitParameter).
      with(/public|files|merb\.env/).any_number_of_times.and_return nil
    @rack_context.should_receive(:getInitParameter).
      with("merb.root").and_return("merb/root")
    @rack_context.should_receive(:getRealPath).
      with("merb/root").and_return(@app_path)
    @app_factory.init(@rack_context)
    app = @app_factory.getApplication
    app.should respond_to(:call)
  end
end
