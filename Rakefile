task default: 'test:fast'

namespace :test do
  desc 'Runs tests until it sees a failure'
  task(:fast) { sh 'bundle exec mrspec --fail-fast' }

  desc 'Runs tests until it sees a failure'
  task(:all) { sh 'bundle exec mrspec --fail-fast' }
end
