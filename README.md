# dry4r

dry4r finds candidate duplicate Ruby code across files and directories. It reports fuzzy structural matches by filename and line range so another mechanism can evaluate and reduce duplication.

It is a Ruby port of [dry4go](https://github.com/unclebob/dry4go) (and its siblings [dry4clj](https://github.com/unclebob/dry4clj) and [dry4java](https://github.com/unclebob/dry4java)) by Robert C. Martin.

## Overview

dry4r compares Ruby method definitions by converting each method body and
signature shape into a normalized syntax tree. The normalized tree is walked to
collect a set of structural fingerprints, one for the whole method and one for
each nested syntax node.

Similarity is Jaccard similarity over those fingerprint sets:

```text
score = shared fingerprints / all fingerprints seen in either method
```

A score of `1.0` means the normalized structures have the same fingerprint set.
Lower scores mean the methods still share structure, but each method also has
structure the other does not. The default `--threshold 0.82` reports candidates
whose normalized structures are close enough to be worth review.

The Ruby parser is [prism](https://github.com/ruby/prism). Identifiers, local
names, method names, and literal values normalize away. Structural Ruby syntax
is preserved, including:

- def / def self. method shape
- parameter groups (required, optional, rest, keyword, block)
- blocks and statement order
- `if`, `unless`, `while`, `until`, `for`, `case`, `begin`/`rescue`/`ensure`
- assignments, returns, calls, indexing, ranges
- array/hash literals, lambdas, operators such as `+`, `==`, `&&`, `||`

For example, these methods match strongly even though their names, local
variables, predicates, and field names differ:

```ruby
def alpha(xs)
  ys = []
  xs.each do |x|
    ys << x + 1 if x.odd?
  end
  ys
end

def beta(items)
  kept = []
  items.each do |item|
    kept << item + 1 if item.even?
  end
  kept
end
```

## Installation

Add to your Gemfile:

```ruby
gem "dry4r"
```

Or install directly:

```bash
gem install dry4r
```

## Usage

```bash
dry4r [options] [file-or-directory ...]
```

Options:

```text
--threshold N   Minimum structural similarity score, default 0.82
--min-lines N   Minimum source lines in a candidate method, default 4
--min-nodes N   Minimum normalized syntax nodes, default 20
--format F      text or json, default text
--json          Same as --format json
--text          Same as --format text
--help, -h      Show this message
```

Examples:

```bash
dry4r .
dry4r lib/foo.rb lib/bar.rb
dry4r --json --threshold 0.9 lib spec
```

Every file named on the command line participates in the same duplication
search. When an argument is a directory, dry4r recursively includes every `.rb`
and `.rake` file under that directory in the same search set, skipping `.git`,
`vendor`, `target`, `node_modules`, `tmp`, and `coverage` directories.

Default text output is intended for quick reading:

```text
DUPLICATE score=0.89
  lib/billing/invoice.rb:12-25
  lib/billing/receipt.rb:30-44
```

JSON output is intended for tools:

```json
{
  "candidates": [
    {
      "score": 0.89,
      "left": {"file": "lib/billing/invoice.rb", "start_line": 12, "end_line": 25},
      "right": {"file": "lib/billing/receipt.rb", "start_line": 30, "end_line": 44},
      "left_nodes": 88,
      "right_nodes": 91
    }
  ]
}
```

## Development

Requires Ruby 3.0+.

```bash
bundle install
bundle exec rake             # rubocop + rspec
bundle exec rake lint        # rubocop only
bundle exec rake spec        # rspec only
bundle exec rake coverage    # rspec under SimpleCov
bundle exec rake crap        # CRAP scores via crap4r
bundle exec rake mutant      # mutation testing via mutant-rspec
```

The test suite uses [rspec](https://rspec.info), linting uses
[rubocop](https://rubocop.org) (with `rubocop-rake` and `rubocop-rspec`), code
coverage uses [SimpleCov](https://github.com/simplecov-ruby/simplecov), CRAP
scoring uses [crap4r](https://github.com/kjeldahl/crap4r), and mutation testing
uses [mutant](https://github.com/mbj/mutant). GitHub Actions runs a lint job
and the spec suite on Ruby 3.1, 3.2, and 3.3 on every push and pull request.

## License

MIT, see [LICENSE](LICENSE).
