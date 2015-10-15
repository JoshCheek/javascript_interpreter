RSpec.describe 'The JS interpreter' do
  it 'can set and lookup local variables'

  describe 'function instantiation' do
    it 'makes a new object whose __proto__ is set to the function\'s prototype'
  end

  describe 'method invocation' do
    it 'passes the arguments to the function'
    it 'can see variables from the enclosing environment'
    it 'has its own set of local variables'
  end

  describe 'core libs' do
    describe 'numbers' do
      it 'evaluates to a floating point number of the same value'
    end

    describe 'String' do
      it 'treats addition as concatenation'
    end

    describe 'Date' do
      it 'initializes to the current time'
      it 'subtracts to milliseconds'
    end

    describe 'console' do
      specify '#log prints strings to stdout'
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
