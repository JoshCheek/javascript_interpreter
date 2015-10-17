require 'js_simulated_blocking'

RSpec.configure do |config|
  config.before not_implemented: true do
    pending 'not implemented!'
  end
end

require 'time'
class MockTime < Time
  def self.for(callable)
    callable ||= lambda { Time.now }
    Class.new self do
      define_method(:now) { callable.call }
    end
  end

  def where_now_is(callable)
    @get_now = callable
    self
  end

  def now
    get_now.call
  end

  private

  def get_now
    @get_now || lambda { super }
  end
end

RSpec.describe 'The JS interpreter' do
  def interprets!(code, assertions_and_attrs={})
    time_proc   = assertions_and_attrs.delete :time
    assertions  = assertions_and_attrs
    time        = MockTime.for time_proc
    stdout      = StringIO.new
    interpreter = JsSimulatedBlocking.eval code, stdout: stdout, time: time
    assertions.each do |type, expectation|
      case type
      when :result
        expect(interpreter.result).to eq expectation
      when :logged
        expect(stdout.string).to eq expectation
      when :locals
        locals = interpreter.env.all_visible
        expectation.each do |name, value|
          expect(locals.fetch name).to eq value
        end
      else raise "You need to define the assertion for #{type.inspect}"
      end
    end
    interpreter
  end

  it 'can set and lookup local variables', passing: true do
    interprets! 'var a = 1, b = 2; a+b',
                locals: {a: 1, b: 2},
                result: 3
  end

  describe 'function instantiation', passing: true do
    def assert_object(object, assertions)
      assertions.each do |type, expectation|
        case type
        when :constructor
          expect(object.constructor).to eq expectation
        when :__proto__
          expect(object.__proto__).to eq expectation
        else raise "You need to define the assertion for #{type.inspect}"
        end
      end
    end

    it 'makes a new object whose __proto__ is set to the function\'s prototype' do
      interpreter = interprets! 'var klass = function() {}; var instance = new klass()'
      instance    = interpreter.local :instance
      klass       = interpreter.local :klass
      assert_object instance, constructor: klass, __proto__: klass.prototype
    end
  end

  describe 'method invocation', passing: true do
    it 'evaluates to the return value when called' do
      interprets! 'var fn = function() { return 123 }; fn() + fn()', result: 246
    end

    it 'passes the arguments to the function' do
      interprets! 'var fn = function(n) { return n + n }; fn(1)', result: 2
    end

    it 'can return early from the function' do
      interprets! '(function() { return 1; return 2; })(10000)', result: 1
    end

    it 'can see variables from the enclosing environment' do
      interprets! 'var outer = 1; var fn = function() { return outer }; fn()', result: 1
    end

    it 'has its own set of local variables' do
      interprets! 'var outer = 1; var fn = function(inner) { return outer + inner + 3 }; fn(2)', result: 6
    end
  end

  describe 'core libs' do
    describe 'singleton literals', passing: true do
      it 'interprets true' do
        interprets! 'true', result: true
      end
      it 'interprets false' do
        interprets! 'false', result: false
      end
      it 'interprets null' do
        interprets! 'null', result: nil
      end
    end

    describe 'numbers', passing: true do
      it 'evaluates to a floating point number of the same value' do
        interpreter = interprets! '1'
        expect(interpreter.result).to eq 1.0
        expect(interpreter.result.class).to eq Float
      end

      specify '#+ adds numbers together' do
        interprets! '1+2', result: 3
      end
    end

    describe 'String', passing: true do
      it '#+ concatenates' do
        interprets! '"a" + "b"', result: "ab"
      end
    end

    describe 'Date' do
      it 'initializes to the current time', not_implemented: true do
        ruby_time   = Time.now
        interpreter = interprets! 'new Date()', time: lambda { time }
        js_time     = interpreter.result
        expect(js_time.year ).to eq ruby_time.year
        expect(js_time.month).to eq ruby_time.month
        expect(js_time.day  ).to eq ruby_time.day
        expect(js_time.sec  ).to eq ruby_time.sec
      end

      it 'has a to_s that matches "Thu Oct 15 2015 04:56:32 GMT-0600 (MDT)"', not_implemented: true do
        ruby_time = Time.parse "Thu Oct 15 2015 04:56:32 GMT-0600 (MDT)"
        interprets! 'new Date().toString()', time: lambda { time }, result: "Thu Oct 15 2015 04:56:32 GMT-0600 (MDT)"
      end

      it 'subtracts to milliseconds', not_implemented: true do
        interpreter = interprets! 'new Date() - new Date()'
        milliseconds = interpreter.result
        expect(milliseconds).to be >= 0
        expect(milliseconds).to be < 100 # tenth of a second
      end
    end

    describe 'console', passing: true do
      specify '#log prints strings to stdout' do
        interprets! 'console.log("hello")', logged: "hello\n"
      end
    end

    describe 'setTimeout', not_implemented: true do
      context 'when given a function and a duration' do
        it 'returns immediately, placing the callback into the event queue once the duration has passed'
      end

      context 'when given just a duration' do
        it 'moves to the next item in the event queue and places the entire callstack into the event queue once the duration has passed'
      end
    end
  end
end
