# Charts

Charts is a gem that can parse markdown-like text and turn it into SVG files.

![Gantt Chart](https://cloud.githubusercontent.com/assets/3074765/24520143/6a5e0b06-1555-11e7-9ecc-041e7f34a3ef.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'charts'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install charts

## Usage

### Gantt Chart

```ruby
require 'charts'

chart = <<EOF
gantt
title My Title
numberFormat .%2f

row 0, :group1, 0.000, 0.100
row 1, :group1, 0.100, 0.200
row 2, :group1, 0.200, 0.300
EOF
Charts.render_chart(chart, 'my_chart.svg')
```

### Flowchart

```ruby
require 'charts'

chart = <<EOF
graph
A-->B
B--text-->C
EOF
Charts.render_chart(chart, 'my_chart.svg')
```

### DOT Format

Full support for GraphViz's .dot format

```ruby
require 'charts'

chart = <<EOF
graph graphname {
  a -- b -- c;
  b -- d;
}
EOF
Charts.render_chart(chart, 'my_chart.svg')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. It is developed using the ruby version indicated in `dev.yml`. You will also need the homebrew packages listed in `dev.yml`, or the corresponding Linux packages if you are using Linux.

Then, run `bin/testunit` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/charts. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

