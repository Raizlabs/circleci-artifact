# circleci_artifact


This library is designed to make fetching the URLs for [CircleCI build artifacts](https://circleci.com/docs/2.0/artifacts/#downloading-all-artifacts-for-a-build-on-circleci) quick and easy. Unfortunately CircleCI makes it difficult to get the URLs for your build artifacts without hitting their API, so it's not straightforward to include links to your artifacts as part of the CI process.

This gem was built to be used in combination with tools like [Fastlane](https://github.com/fastlane/fastlane) and [Danger](https://github.com/danger/danger). The functionality is very limited at this point, and just makes it easier to grab single artifacts whose URL match a substring.

## Getting Started

* Create a new CircleCI account for your CI bot user.
* Create a CircleCI API token in the application by going to [User Settings > Personal API Tokens](https://circleci.com/account/api).
* Create a new token called `CIRCLE_API_TOKEN`. 
* Add `CIRCLE_API_TOKEN` to the CircleCI build environment for the target repo.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'circleci_artifact'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install circleci_artifact

## Usage


```ruby
require 'circleci_artifact'
include CircleciArtifact

# Set this yourself using the steps in "Getting Started"
token = ENV['CIRCLE_API_TOKEN']

# These are already in the Circle environment
# https://circleci.com/docs/2.0/env-vars/#build-specific-environment-variables
username = ENV['CIRCLE_PROJECT_USERNAME']
reponame = ENV['CIRCLE_PROJECT_REPONAME']
build = ENV['CIRCLE_BUILD_NUM']

fetcher = Fetcher.new token, username, reponame, build

xcov = ResourceQuery.new 'xcov', 'xcov/index.html'
slather = ResourceQuery.new 'slather', 'slather/index.html'
screenshots = ResourceQuery.new 'screenshots', 'screenshots/index.html'
queries = [xcov, slather, screenshots]
results = fetcher.fetch(queries)

xcov_url = results.url_for_query(xcov)
slather_url = results.url_for_query(slather)
screenshots_url = results.url_for_query(screenshots)

puts "queries: #{queries}"
puts "xcov_url #{xcov_url}"
puts "slather_url #{slather_url}"
puts "screenshots_url #{screenshots_url}"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Raizlabs/circleci_artifact. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CircleciArtifact project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Raizlabs/circleci_artifact/blob/master/CODE_OF_CONDUCT.md).
