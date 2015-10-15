require 'js_simulated_blocking'
require 'js_simulated_blocking/errors'

class JsSimulatedBlocking
  class Binary
    class InvalidInvocation < JsSimulatedBlocking::Error
      def initialize(program_name, reason)
        super "Usage: #{program_name} JSFILE\n#{reason}"
      end
    end

    def self.call(**args)
      new(**args).call
    end

    def initialize(program_name:, argv:, stdout:, stderr:)
      self.argv         = argv
      self.stdout       = stdout
      self.stderr       = stderr
      self.program_name = program_name
    end

    def call
      unexpected_args.any? and
        raise InvalidInvocation.new(program_name, "Should only be one argument, you gave #{argv.length}, #{argv.inspect}")

      filename or
        raise InvalidInvocation.new(program_name, "Please provide a filename")

      File.exist? filename or
        raise InvalidInvocation.new(program_name, "No such file: #{filename.inspect}")

      javascript = File.read(filename)
      JsSimulatedBlocking::Parse.string(javascript, stdout: stdout).call
      return 0

    rescue JsSimulatedBlocking::Error => err
      stderr.puts err.message
      return 1
    rescue JsSimulatedBlocking::SyntaxError => err
      stderr.puts "Syntax error (#{err.message})"
      return 1
    end

    private

    attr_accessor :program_name, :argv, :stdout, :stderr

    def filename
      argv.first
    end

    def unexpected_args
      argv.drop 1
    end
  end
end
