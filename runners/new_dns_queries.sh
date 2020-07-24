#!/bin/bash

nohup tail -F /var/corelight/spool/logger/notice.log | ruby ../ruby/log_monitoring/new_dns_queries.rb > ~/new_dns_queries_stdout.log &