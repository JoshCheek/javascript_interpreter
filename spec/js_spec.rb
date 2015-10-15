require 'js_simulated_blocking'

RSpec.describe 'The JS interpreter' do
  def interprets!(code, assertions={})
    interpreter = JsSimulatedBlocking.from_string(code, stdout: StringIO.new).call
    assertions.each do |type, expectation|
      case type
      when :result then expect(interpreter.result).to eq expectation
      else raise "You need to define the assertion for #{type.inspect}"
      end
    end
    interpreter
  end

  it 'can set and lookup local variables', t: true do
    interprets! 'var a = 1; var b = 2; a',
                locals: {a: 1, b: 2},
                result: 2
  end

  describe 'function instantiation' do
    it 'makes a new object whose __proto__ is set to the function\'s prototype' do
      interpreter = interprets! 'var klass = function() {}; var instance = new klass()'
      instance    = interpreter.local :instance
      klass       = interpreter.local :klass
      assert_object instance, constructor: klass, __proto__: klass.prototype
    end
  end

  describe 'method invocation' do
    it 'evaluates to the return value when called' do
      interprets! 'var fn = function() { return 123 }; fn() + fn()', result: 246
    end

    it 'passes the arguments to the function' do
      interprets! 'var fn = function(n) { return n + n }; fn(1)', result: 2
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

    # TODO: will probably work better to mock out the time
    describe 'Date' do
      it 'initializes to the current time' do
        interpreter = interprets! 'new Date()'
        js_time, ruby_time = interpreter.result, Time.now
        expect(js_time.year ).to eq ruby_time.year
        expect(js_time.month).to eq ruby_time.month
        expect(js_time.day  ).to eq ruby_time.day
        expect(js_time.sec  ).to eq ruby_time.sec
      end

      it 'subtracts to milliseconds' do
        interpreter = interprets! 'new Date() - new Date()'
        milliseconds = interpreter.result
        expect(milliseconds).to be >= 0
        expect(milliseconds).to be < 100 # tenth of a second
      end
    end

    describe 'console' do
      specify '#log prints strings to stdout' do
        interprets! 'console.log("hello")', logged: ['hello']
      end
    end

    describe 'setTimeout' do
      context 'when given a function and a duration' do
        it 'returns immediately, placing the callback into the event queue once the duration has passed'
      end

      context 'when given just a duration' do
        it 'moves to the next item in the event queue and places the entire callstack into the event queue once the duration has passed'
      end
    end
  end
end
