require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'elasticsearch'
require 'patron'

require 'json'
require 'date'


module Sensu::Extension

  class Elastic < Handler

    def name
      'elastic'
    end

    def description
      'outputs metrics to ES'
    end

    def post_init
      @esclient = Elasticsearch::Client.new host: settings['elastic']['host'], timeout: settings['elastic']['timeout']
      @index = settings['elastic']['index']
      @type = settings['elastic']['type']
    end

    def run(event)
      begin
        event = parse_event(event)
        # set origHost to clean up FQDN later
        origHost = event['client']['name'].downcase
        host = event['client']['name'].split('.').first.downcase
        series = event['check']['name']
        timestamp = event['check']['issued']
        duration = event['check']['duration']
        output = event['check']['output']
        tags = event['client']['tags']

      if tags
        tags = JSON.parse(tags.to_json)
        tags.each { |x,y|
        if x.to_s == 'app' || x.to_s == 'apps' ||  x.to_s == 'applications' || x.to_s == 'service' || x.to_s == 'services'
                if y.class == Array
                list = Hash[tags[x].map { |key| [key, true] }]
                else
                list = {}
                list[y] = true
                end
                tags.delete(x)
                tags = tags.merge(list)
        end

        }
    end
      rescue => e
        @logger.error("ES: Error setting up event object - #{e.backtrace.to_s}")
      end

      begin
        vmhost = nil
        chost = nil
        points = []
        output.split(/\n/).each do |line|
          @logger.debug("Parsing line: #{line}")
          k,v,t = line.split(/\s+/)
          # Catch vmware metrics and spoof the host information so it 
          # appears it's coming from each independent virtual instead of the infra host
          if k.include? "VMCATCH"
            host = k.split('.').first.downcase
            k = k.downcase.gsub(/#{origHost}|#{host}/, 'metrics')
            # Determine if it's a virtual or a physical host
            if k.include? "_vmcatch"
              splitVersion = k.split('_')
              if splitVersion.length < 3
                vmhost = splitVersion.first
              else
                chost = splitVersion.first
              end
            end
          else
            # Clean up fqdn so we only have the hostname
            # This fixes issues with the metrics being for the domain instead of the host
            k = k.downcase.gsub(/#{origHost}|#{host}/, 'metrics')
          end
          v = v.match('\.').nil? ? Integer(v) : Float(v) rescue v.to_s
          if tags
            point = {:@timestamp => Time.parse(Time.at(t.to_i).to_s).iso8601, :host => host, :metric => k.sub("metrics.",""), :value => v, :tags => tags}
            point = point.merge(tags)
          elsif vmhost
            point = {:@timestamp => Time.parse(Time.at(t.to_i).to_s).iso8601, :host => host, :vmhost => vmhost.sub("metrics.", ""), :metric => k.sub("metrics.",""), :value => v} 
          elsif chost
            point = {:@timestamp => Time.parse(Time.at(t.to_i).to_s).iso8601, :host => host, :chost => chost.sub("metrics.", ""), :metric => k.sub("metrics.",""), :value => v}
          else
            point = {:@timestamp => Time.parse(Time.at(t.to_i).to_s).iso8601, :host => host, :metric => k.sub("metrics.",""), :value => v}
          end
          point = { index:  { _index: @index, _type: @type, data: point } }
          points << point
        end
      rescue => e
        @logger.error("ES: Error parsing output lines - #{e.backtrace.to_s}")
        @logger.error("ES: #{output}")
      end

      begin
          @esclient.bulk body: points
      rescue => e
        @logger.error("ES: Error indexing event - #{e.backtrace.to_s}")
      end
      yield("ES: Handler finished", 0)
    end

    def parse_event(event_data)
      begin
        event = JSON.parse(event_data)

        # override default values for non-existing keys
        event['check']['time_precision'] ||= 's' # n, u, ms, s, m, and h (default community plugins use standard epoch date)
        event['check']['influxdb'] ||= {}
        event['check']['influxdb']['tags'] ||= {}
        event['check']['influxdb']['database'] ||= nil

        rescue => e
          puts "Failed to parse event data: #{e}"
        end
        return event
    end
  end
end
