require 'js_simulated_blocking'

class JsSimulatedBlocking
  class Binary
    def self.call(**args)
      new(**args).call
    end

    attr_accessor :program_name, :argv, :stdout, :stderr

    def initialize(program_name:, argv:, stdout:, stderr:)
      self.argv         = argv
      self.stdout       = stdout
      self.stderr       = stderr
      self.program_name = program_name
    end

    def call
      error_message = validate_args()

      if error_message
        stderr.puts "Usage: #{program_name} JSFILE\n#{error_message}"
        return 1
      end

      js = File.read(filename)
      begin
        JsSimulatedBlocking.from_string(js, stdout: stdout).call
      rescue JsSimulatedBlocking::SyntaxError => err
        stderr.puts "Syntax error (#{err.message})"
        return 1
      end
    end

    private

    def filename
      argv.first
    end

    def unexpected_args
      argv.drop 1
    end

    def validate_args
      if unexpected_args.any?
        "Should only be one argument, you gave #{ARGV.length}, #{ARGV.inspect}"
      elsif !filename
        "Please provide a filename"
      elsif !File.exist?(filename)
        "No such file: #{filename.inspect}"
      end
    end
  end
end
