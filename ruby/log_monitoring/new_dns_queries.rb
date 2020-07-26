require_relative '../lib/emailer'
require "json"

mut = Mutex.new
new_domains = []

emailer = Emailer.new("inbound-smtp.us-east-1.amazonaws.com")
TIME_BETWEEN_EMAILS = 600

Thread.new do 
  mut.synchronize do
    unless new_domains.empty?
      domains = []
      body = ""
      new_domains.each do |domain|
        body += domain['msg'] + "\n"
      end

      body += "\n"

      new_domains.each do |domain|
        body += JSON.pretty_unparse(domain) + "\n------------------------------\n"
      end
      emailer.send_alert_email("New Domains Observed (#{new_domains.length} domains)", body, "zeek@raptormail.net", "Zeek", "rvictory@raptormail.net", "Ryan Victory")
    end
    new_domains = []
  end
  sleep TIME_BETWEEN_EMAILS
end


STDIN.each_line do |line|
  begin
    data = JSON.parse(line)
  rescue
    next
  end
  next unless data["note"] == "DNSMonitor::DNS_New_FQDN"
  puts "Queued #{data['msg']}"
  mut.synchronize do
    new_domains.push(data)
  end
end