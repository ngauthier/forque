require 'rubygems'
require 'ohai'
require 'base64'

class Forque
  def initialize(*items)
    @items = Array(items)
  end

  def collect(&blk)
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
            begin
              result = blk.call(input)
            rescue Exception => ex
              result = ForqueExceptionWrapper.new(ex) 
            end
            child_write.write(encode(result)+"\n")
          end
        rescue Interrupt
          # init forque aborted
          child_read.close
          child_write.close
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

    result = []

    children_pipes.each do |p|
      listener_threads << Thread.new do
        begin
          while input = p[:read].gets
            input = decode(input.chomp)
            if ForqueExceptionWrapper === input
              raise input.exception
            end
            result << input
            if items_to_send.empty?
              p[:read].close
              p[:write].close
              break
            else
              p[:write].write(encode(items_to_send.pop)+"\n")
            end
          end
        rescue Interrupt
          # listener forque aborted
          p[:read].close
          p[:write].close
          raise "Forque Aborted"
        end
      end
    end

    listener_threads.each do |t|
      begin
        t.join
      rescue Interrupt
        # listener died
      end
    end

    children_pids.each do |p|
      begin
        Process.wait(p)
      rescue Interrupt
        # child died
      end
    end

    return result
  end

  class ForqueExceptionWrapper
    attr_reader :exception
    def initialize(exception)
      @exception = exception
    end
  end

  private

  # detect system
  ohai = Ohai::System.new
  ohai.all_plugins
  THREADS = ohai['cpu']['total']

  def encode(obj)
    Base64.encode64(Marshal.dump(obj)).split("\n").join
  end

  def decode(str)
    Marshal.load(Base64.decode64(str))
  end
end

