# zeek-scripts-and-such
A place for my random work with Zeek and Zeek-related things

# Procedure for creating AWS Importer:
1. Create Kinesis stream for log
1. Create Glue schema
1. Create Firehose delivery stream
1. Create DynamoDB Aggregation Table
1. Create Lambda for Aggregation
1. Start Sending data