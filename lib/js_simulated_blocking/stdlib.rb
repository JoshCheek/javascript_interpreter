require 'js_simulated_blocking/functions'

class JsSimulatedBlocking
  class Stdlib
    def self.global(stdout:, time:)
      Env.new
         .declare(:console, console(stdout: stdout))
         .declare(:Date,    Date(time: time))
    end

    def self.console(stdout:)
      log = InternalFunction.new do |args|
        stdout.puts(args.join ' ')
      end

      {log: log}
    end

    def self.Date(time)
      InternalFunction.new name: :Date do |date|
        require "pry"
        binding.pry
      end
    end
  end
end
