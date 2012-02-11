require 'optparse'
require 'amqp'
require 'eventmachine'

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
          :port => nil,
          :exchange => {
            :name => nil,
            :kind => :topic,
          },
          :queue => '',
          :vhost => '/',
          :via_ssl => false,
          :ssl_cert => nil,
          :ssl_key => nil,
          :ssl_verify => false
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
            @options[:amqp][:exchange][:kind] = type.to_sym
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
        opts.on("--ssl_cert CERT", "Path to SSL chain certificates") do |c|
          @options[:amqp][:ssl_cert] = c
        end
        opts.on("--ssl_key PRIVKEY", "Path to SSL private key") do |k|
          @options[:amqp][:ssl_key] = k
        end

        opts.separator ""
        opts.separator "Consumer Options: "
        opts.on("--queue QUEUE", "The queue on which to listen.") {
          |q| @options[:amqp][:queue] = q
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

      EventMachine.run do
        AMQP.connect(:host => amqp[:host], :port => amqp[:port], :vhost => amqp[:vhost],
          :username => amqp[:username], :password => amqp[:password], :ssl => {
            :cert_chain_file => amqp[:ssl_cert],
            :private_key_file => amqp[:ssl_key]
          },
          :on_tcp_connection_failure => Proc.new { |settings|
            puts "TCP Connection failure; details:\n\n#{settings.inspect}\n\n"; exit 1
          },
          :on_possible_authentication_failure => Proc.new { |settings|
            puts "Authentication failure, I'm afraid:\n\n#{settings.inspect}\n\n"; exit 1
          }) do |connection|

          channel  = AMQP::Channel.new(connection)
          case amqp[:exchange][:kind]
          when :direct
            exchange = channel.direct(amqp[:exchange][:name])
          when :fanout
            exchange = channel.fanout(amqp[:exchange][:name])
          when :topic
            exchange = channel.topic(amqp[:exchange][:name])
          end

          if @options[:publish]
            exchange.publish(@arguments[0], :routing_key => amqp[:key]) do
              connection.disconnect { EM.stop }
            end
          else
            channel.queue(amqp[:queue]).bind(exchange, :key => amqp[:key]).subscribe do |payload|
              puts payload
            end
          end

        end
      end # EM
    end # run!

  end
end
