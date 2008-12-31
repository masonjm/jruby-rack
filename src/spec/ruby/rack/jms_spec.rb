#--
# Copyright 2007-2008 Sun Microsystems, Inc.
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

import org.jruby.rack.jms.QueueContextListener
import org.jruby.rack.jms.QueueManager
import org.jruby.rack.jms.DefaultQueueManager

describe QueueContextListener do
  before :each do
    @qmf = mock "queue manager factory"
    @qm = mock "queue manager"
    @listener_event = javax.servlet.ServletContextEvent.new @servlet_context
    @listener = QueueContextListener.new @qmf
  end
  
  it "should create a new QueueManager, initialize it and store it in the application context" do
    @qmf.should_receive(:newQueueManager).ordered.and_return @qm
    @qm.should_receive(:init).with(an_instance_of(RackContext)).ordered
    @servlet_context.should_receive(:setAttribute).with(QueueContextListener::MGR_KEY, an_instance_of(QueueManager)).ordered
    @listener.contextInitialized(@listener_event)
  end

  it "should capture exceptions during initialization and log them to the servlet context" do
    @qmf.should_receive(:newQueueManager).and_return @qm
    @qm.should_receive(:init).and_raise StandardError.new("something happened!")
    @listener.contextInitialized(@listener_event)
  end
  
  it "should remove the QueueManager and destroy it" do
    qm = QueueManager.impl {}
    @servlet_context.should_receive(:getAttribute).with(QueueContextListener::MGR_KEY).and_return qm
    @servlet_context.should_receive(:removeAttribute).with(QueueContextListener::MGR_KEY)
    qm.should_receive(:destroy)
    @listener.contextDestroyed(@listener_event)
  end
end

describe DefaultQueueManager do
  before :each do
    @connection_factory = mock "jms connection factory"
    @context = mock "jndi context"
    @queue_manager = DefaultQueueManager.new(@connection_factory, @context)
    @queue_manager.init(@rack_context)
  end

  it "should set up a connection with a message listener" do
    app_factory = RackApplicationFactory.impl {}
    @rack_context.should_receive(:getRackFactory).and_return app_factory
    conn = mock "connection"
    @connection_factory.should_receive(:createConnection).and_return conn
    session = mock "session"
    conn.should_receive(:createSession).and_return session
    dest = javax.jms.Destination.impl {}
    @context.should_receive(:lookup).with("myqueue").and_return dest
    consumer = mock "consumer"
    session.should_receive(:createConsumer).with(dest).and_return consumer
    consumer.should_receive(:setMessageListener).with(an_instance_of(javax.jms.MessageListener))
    conn.should_receive(:start)
    @queue_manager.listen("myqueue")
  end
end