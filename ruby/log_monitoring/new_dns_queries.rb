require_relative '../lib/emailer'
require "json"

emailer = Emailer.new("inbound-smtp.us-east-1.amazonaws.com")

STDIN.each_line do |line|
  begin
    data = JSON.parse(line)
  rescue
    next
  end
  next unless data["note"] == "DNSMonitor::DNS_New_FQDN"
  emailer.send_alert_email(data["msg"], JSON.pretty_unparse(data), "zeek@raptormail.net", "Zeek", "rvictory@raptormail.net", "Ryan Victory")
  puts "Sent #{data['msg']}"
end