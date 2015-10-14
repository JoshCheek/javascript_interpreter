require 'open3'

def self.from_root(path)
  root_dir = File.expand_path '..', __dir__
  File.join(root_dir, path).freeze
end

bin_path                                  = from_root 'bin/js'
nonexistent_path                          = from_root 'path/to/nothing'
fixture_illustrates_simulated_nonblocking = from_root 'examples/simulated_nonblocking.js'
fixture_invalid_syntax                    = from_root 'examples/invalid.js'

RSpec.describe 'Acceptance' do
  it 'can run an example program that illustrates the simulated blocking' do
    skip 'Haven\'t gotten around to making it work yet ;)'
    stdout, stderr, status = Open3.capture3(bin_path, fixture_illustrates_simulated_nonblocking)
    expect(stderr).to be_empty
    expect(status).to be_success

    # truncated to deciseconds to mitigate time fluctuations
    expect(stdout.scan /(first|second|third) \d\d/).to eq [
      "second 10",
      "first 20",
      "third 30",
    ]
  end

  define_singleton_method :is_bad_invocation do |explanation, argv|
    example "(example: #{explanation})" do
      stdout, stderr, status = Open3.capture3(bin_path, *argv)
      expect(stdout).to be_empty
      expect(stderr).to include "Usage"
      expect(status).to_not be_success
    end
  end

  describe 'explodes helpfully when invoked incorrectly' do
    is_bad_invocation "No args",           []
    is_bad_invocation "Arg is not a file", [nonexistent_path]
    is_bad_invocation "Multiple args",     [fixture_illustrates_simulated_nonblocking,
                                            fixture_illustrates_simulated_nonblocking]
  end

  it 'explodes helpfully when the syntax is not valid js' do
    skip "Not far enough along yet for syntax"
    stdout, stderr, status = Open3.capture3(bin_path, fixture_invalid_syntax)
    expect(stdout).to be_empty
    expect(stderr).to match /syntax/
    expect(status).to_not be_success
  end
end
