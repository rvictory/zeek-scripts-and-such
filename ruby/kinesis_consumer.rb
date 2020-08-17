require "aws-sdk-kinesis"

AWS_REGION = ENV['AWS_REGION'] || "us-east-2"
FIREHOSE_STREAM_NAME = ENV['FIREHOSE_STREAM']

firehose_client = Aws::Kinesis::Client.new(
    region: AWS_REGION
)

puts "Created Firehose client for stream #{FIREHOSE_STREAM_NAME} with a batch size of #{BATCH_SIZE}"


