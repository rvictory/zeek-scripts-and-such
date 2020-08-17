# Takes JSON logs and sends them to Kinesis
# Credentials are expected to be in the environmental variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# or in the ~/.aws/credentials file
require "aws-sdk-kinesis"

AWS_REGION = ENV['AWS_REGION'] || "us-east-2"
FIREHOSE_STREAM_NAME = ENV['FIREHOSE_STREAM']
BATCH_SIZE = ENV['BATCH_SIZE'].nil? ? 5 || ENV['BATCH_SIZE'].to_i

firehose_client = Aws::Kinesis::Client.new(
    region: AWS_REGION
)

puts "Created Firehose client for stream #{FIREHOSE_STREAM_NAME} with a batch size of #{BATCH_SIZE}"

batch = []
STDIN.each_line do |line|
    batch.push(line.chomp)
    if batch.length == BATCH_SIZE
        begin
            resp = client.put_records({
                records: batch.map {|x| {data: x, partition_key: "PartitionKey"} }
                stream_name: FIREHOSE_STREAM_NAME
            })
            puts "Wrote batch"
            if resp.failed_record_count > 0
                puts "Failed record count was greater than 0"
            end 
        rescue => exception
           puts "Failed to put batch: #{exception.message}" 
        end
        batch = []
    end
end