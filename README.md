# manageiq-style

[![Gem Version](https://badge.fury.io/rb/manageiq-style.svg)](http://badge.fury.io/rb/manageiq-style)
[![CI](https://github.com/ManageIQ/manageiq-style/actions/workflows/ci.yaml/badge.svg)](https://github.com/ManageIQ/manageiq-style/actions/workflows/ci.yaml)

Style and linting configuration for ManageIQ projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'manageiq-style'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install manageiq-style

## Usage

In the root of the repo that needs configuring, run `bundle exec manageiq-style -i` to install or update the rubocop configuration files.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ManageIQ/manageiq-style. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ManageIQ/.github/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the manageiq-style project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ManageIQ/.github/blob/master/CODE_OF_CONDUCT.md).
