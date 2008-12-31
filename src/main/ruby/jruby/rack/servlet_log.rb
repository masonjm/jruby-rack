#--
# Copyright 2007-2008 Sun Microsystems, Inc.
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

class JRuby::Rack::ServletLog
  def initialize(context = $servlet_context)
    @context = context
  end

  def puts(msg)
    write msg.to_s
  end

  def write(msg)
    @context.log(msg)
  end

  def flush
  end

  def close
  end
end
