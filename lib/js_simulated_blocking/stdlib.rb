require 'js_simulated_blocking/env'
require 'js_simulated_blocking/data_structures'

class JsSimulatedBlocking
  class Stdlib
    # uhm, what is the toplevel object? pretty sure these vars should be strored there instead of in the env
    def self.global(stdout:, time:, env: env)
      env.declare(:console, console(env: env, stdout: stdout))
         .declare(:Date,    Date(env: env, time: time))
    end

    def self.console(env:, stdout:)
      console = env.new_object

      console[:log] = env.new_internal_function name: 'console.log'.freeze do |fn_call|
        stdout.puts(fn_call.arguments.join ' ')
      end

      console
    end

    def self.Date(env:, time:)
      date = env.new_internal_function name: 'Date'.freeze do |fn_call|
        fn_call.this.set_internal time: time.now
      end

      date.prototype[:toString] = env.new_internal_function name: 'Date.toString'.freeze do |fn_call|
        # get_internal is undefined for nil... so this fn call was invoked on nil,
        # but should have been the date:
        #
        #   new Date().toString()
        #
        # so probably the instructions we generate need to be smarter so that
        # the function gets bound to the obj its called on?
        ruby_time = fn_call.this.get_internal(:time)
        ruby_time.strftime "FIXME! %Y%Y%Y%Y%Y"
      end

      date
    end
  end
end
