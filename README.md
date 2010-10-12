# Forque

Making forking easy in ruby.

Pronounced like Torque, or like "for - queue" if you're feeling sassy.

## Usage

Forque implements "collect" just like enumerable, but it will automatically do it across the processors on your system (they are autodetected).

    Forque.new(2, 3, 4).collect{|i| i ** 2}
      => [4, 9, 16]

