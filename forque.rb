require 'rubygems'
require 'ohai'
require 'base64'

class Forque
  include Enumerable

  # detect system
  ohai = Ohai::System.new
  ohai.all_plugins
  THREADS = ohai['cpu']['total']

  def initialize(*items)
    @items = Array(items)
  end

  def each
    children_pids = []
    children_pipes = []
    [THREADS, @items.size].min.times do
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe
      children_pids << Process.fork do
        parent_write.close
        parent_read.close
        begin
          while input = child_read.gets and input != "\n"
            input = decode(input.chomp)
            child_write.write(encode(input)+"\n")
          end
        rescue Interrupt
          STDERR.write "Forque Aborted\n"
        end
      end
      child_write.close
      child_read.close
      children_pipes << {:read => parent_read, :write => parent_write}
    end

    items_to_send = @items.dup

    children_pipes.each do |p|
      p[:write].write(encode(items_to_send.pop) + "\n")
    end

    listener_threads = []

    children_pipes.each do |p|
      listener_threads << Thread.new do
        begin
          while input = p[:read].gets
            input = decode(input.chomp)
            yield(input)
            if items_to_send.empty?
              p[:read].close
              p[:write].close
              break
            else
              p[:write].write(encode(items_to_send.pop)+"\n")
            end
          end
        rescue Interrupt
          STDERR.write "Forque Aborted\n"
        end
      end
    end

    listener_threads.each do |t|
      begin
        t.join
      rescue Interrupt
        STDERR.write "Forque Aborted\n"
      end
    end

    children_pids.each do |p|
      begin
        Process.wait(p)
      rescue Interrupt
        STDERR.write "Forque Aborted\n"
      end
    end
  end

  private

  def encode(obj)
    Base64.encode64(Marshal.dump(obj))
  end

  def decode(str)
    Marshal.load(Base64.decode64(str))
  end
end

