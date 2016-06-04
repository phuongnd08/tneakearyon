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

### Setup your Environment Variables

Tneakearyon can be configured using environment variables. For convenience [dotenv](https://github.com/bkeepers/dotenv) is included as a development dependency so you can setup your environment in `.env`.

First copy `.env.test` to `.env`

```
$ cp .env.test .env
```

Then open up `.env` and replace the dummy values with your actual values.

### Playing around in the Console

Start the irb console

```
$ ./bin/console
```

#### Setup a new Internet Banking Client

Then create an `InternetBanking` instance for the bank you wish to interact with e.g.

```ruby
require 'dotenv'
Dotenv.load
ib = Tneakearyon::Bank::MaybankCambodia::InternetBanking.new
```

#### Fetching Login Details

```ruby
login_details = ib.login_details
# => #<Tneakearyon::LoginDetails:0x00563e70001568 @name="JOE BLOGGS">
```

#### Fetching Bank Accounts

```ruby
bank_accounts = ib.bank_accounts
# => [#<Tneakearyon::BankAccount:0x00563e70019460 @number="0001234556677", @current_balance=#<Money fractional:324637 currency:USD>, @available_balance=#<Money fractional:324637 currency:USD>>]
```

### Transfers

```ruby
transfer = ib.create_transfer!(:from_account => "0001234556677", :to_account => "0001234556678", :amount => Money.new(10000, "USD"))
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dwilkie/tneakearyon.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

