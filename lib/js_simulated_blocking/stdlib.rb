require 'js_simulated_blocking/functions'

class JsSimulatedBlocking
  class Stdlib
    def self.global(**options)
      Env.new.declare(:console, console(**options))
    end

    def self.console(stdout:)
      log = InternalFunction.new do |args|
        stdout.puts(args.join ' ')
      end

      {log: log}
    end
  end
end
