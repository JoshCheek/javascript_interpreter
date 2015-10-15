task default: 'test:all'

namespace :test do
  desc 'Runs tests until it sees a failure'
  task(:all) { sh 'bundle exec mrspec' }

  desc 'Runs unit tests only, no bundler, stops on first failure'
  task(:fast) { sh 'mrspec --fail-fast --tag ~acceptance' }
end
