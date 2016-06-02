# Tneakearyon
Tneakearyon (ធនាគារយន្ត pronounced tneak-ear-yon, literally translates to Bank Machine in Khmer) is a Ruby library for programmatically interacting with Internet Banking.

## Supported Banks

* [Maybank Cambodia](https://www.maybank2u.com.kh/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tneakearyon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tneakearyon

## Usage

```ruby
maybank = Tneakearyon::Bank::MaybankCambodia::WebApi.new(:username => "username", :password => "password")
maybank.fetch_account_details!
maybank.account_details
# => {:login_name=>"JOE BLOGGS", :accounts=>{"000180212345678"=>{:number=>"000180212345678", :current_balance=>#<Money fractional:324637 currency:USD>, :available_balance=>#<Money fractional:324637 currency:USD>}}}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dwilkie/tneakearyon.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

