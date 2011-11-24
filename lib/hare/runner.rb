require 'optparse'
require 'bunny'

module Hare
  trap(:INT) { puts; exit }

  class Runner
    attr_accessor :options
    attr_accessor :arguments

    def initialize(argv)
      @argv = argv

      @options = {
        :logging => false,
        :publish => false,
        :amqp => {
          :host => 'localhost',
          :port => '5672',
          :exchange => {
            :name => nil,
            :kind => :direct,
          },
          :queue => '',
          :vhost => '/',
          :timeout => 0
        }
      }

      parse!
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: hare [options] [MSG]"

        opts.separator ""
        opts.separator "Common Options:"
        opts.on("-h", "--host HOST", "The AMQP server host") {
          |host| @options[:amqp][:host] = host
        }
        opts.on("-p", "--port PORT", "The AMQP server host port") {
          |port| @options[:amqp][:port] = port
        }
        opts.on("--vhost VHOST", "The AMQP vhost on which to connect") {
          |vhost| @options[:amqp][:vhost] = vhost
        }
        opts.on("--exchange_name EXCHANGE", "The name of the AMQP exchange on which to connect") {
          |exc| @options[:amqp][:exchange][:name] = exc
        }
        opts.on("--exchange_type TYPE", "The type of the AMQP exchange on which to connect") do |type|
          if ['topic', 'direct', 'fanout'].member? type
            @options[:amqp][:exchange][:type] = type.to_sym
          else
            puts "Exchange type must be (topic|direct|fanout), not #{type}."
            exit 1
          end
        end
        opts.on("--username NAME", "The AMQP username.") {
          |u| @options[:amqp][:username] = u
        }
        opts.on("--password PSWD", "The AMQP password for the user given.") {
          |p| @options[:amqp][:password] = p
        }
        opts.on("--route_key KEY", "The key to route messages over.") {
          |k| @options[:amqp][:key] = k
        }
        opts.on("--logging", "Enable logging of AMQP interactions.") {
          @options[:logging] = true
        }

        opts.separator ""
        opts.separator "Consumer Options: "
        opts.on("--queue QUEUE", "The queue on which to listen.") {
          |q| @options[:amqp][:queue] = q
        }
        opts.on("--timeout TIME", "The time after which queue subscription will end.") {
          |t| @options[:amqp][:timeout] = t
        }

        opts.separator ""
        opts.separator "Producer Options: "
        opts.on("--producer", "Toggle to enable producing messages") {
          @options[:publish] = true
        }

        opts.separator ""
        opts.on_tail("--help", "Show this message.") do
          puts opts
          exit
        end
        opts.on_tail("-v", "--version", "Show version") {
          puts Hare::VERSION; exit
        }
      end
    end

    def parse!
      parser.parse! @argv
      @arguments = @argv
    end

    def run!
      amqp = @options[:amqp]

      b = Bunny.new(:host => amqp[:host], :port => amqp[:port], :logging => amqp[:logging])
      b.start

      eopts = amqp[:exchange]
      exch = b.exchange(eopts[:name], :type => eopts[:type])

      if @options[:publish]
        exch.publish(@arguments[0].rstrip + "\n", :key => amqp[:key])
      else
        q = b.queue(amqp[:queue])
        q.bind(exch, :key => amqp[:key])
        q.subscribe(:timeout => amqp[:timeout]) do |msg|
          puts "#{msg[:payload]}"
        end
      end

      b.stop
    end

  end
end
