require 'js_simulated_blocking/env'
require 'js_simulated_blocking/data_structures'

class JsSimulatedBlocking
  class Stdlib
    def self.global(stdout:, time:, env: Env.new)
      env.declare(:console, console(env: env, stdout: stdout))
         .declare(:Date,    Date(env: env, time: time))
    end

    def self.console(env:, stdout:)
      log = InternalFunction.new env: env, name: 'console.log'.freeze do |fn_call|
        stdout.puts(fn_call.arguments.join ' ')
      end

      {log: log}
    end

    def self.Date(env:, time:)
      InternalFunction.new env: env, name: :Date do |fn_call|
        require "pry"
        binding.pry
      end
    end
  end
end
