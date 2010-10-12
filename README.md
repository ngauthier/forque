# Forque

Making forking easy in ruby.

Pronounced like Torque, or like "for - queue" if you're feeling sassy.

## Usage

Forque implements "collect" just like enumerable, but it will automatically do it across the processors on your system (they are autodetected).

    Forque.new(2, 3, 4).collect{|i| i ** 2}
      => [4, 9, 16]

## Anticipated Questions

### Why not threads?

Threads only work on a single processor, they are not multicore.

### Why not just split up the tasks?

Then they aren't auto balanced, meaning that one could could end up with lots more work than another.

## It doesn't work on windows

Because windows doesn't have pipes.
