require 'logstash-logger'

logger_type = ENV['LOGGER_TYPE'] || nil
logger_path = ENV['LOGGER_PATH'] || nil
logger_host = ENV['LOGGER_HOST'] || nil
logger_port = ENV['LOGGER_PORT'] || nil
logger_name = ENV['LOGGER_NAME'] || 'windmill-logger'

if logger_type == 'file' and logger_path
  logger = LogStashLogger.new(type: :file, path: 'test.log', sync: true)
elsif logger_type == 'tcp' and logger_host
  logger = LogStashLogger.new(type: :tcp, host: logger_host, port: logger_port, ssl_enable: true)
else
  logger = LogStashLogger.new(type: :stdout)
end

raise "No logging output defined." if logger.nil?

namespace '/logger' do
  post do
    # Add Check that Endpoint is Valid

    return nil unless Endpoint.find_by node_key: params['node_key']

    begin
      logs = JSON.parse(request.body.read)
    rescue
    end

    for log in logs
      puts log
    end

    logger.info "#{logger_name}: #{log}"

    {"node_invalid": false}.to_json
  end
end
