require 'js_simulated_blocking/env'
require 'js_simulated_blocking/data_structures'

class JsSimulatedBlocking
  class Stdlib
    # uhm, what is the toplevel object? pretty sure these vars should be strored there instead of in the env
    def self.global(stdout:, time:, env: Env.new)
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
      env.new_internal_function name: 'Date'.freeze do |fn_call|
        # require "pry"
        # binding.pry
      end
    end
  end
end
