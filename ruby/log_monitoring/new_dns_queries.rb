require_relative '../lib/emailer'
require "json"

mut = Mutex.new
new_domains = []

emailer = Emailer.new("inbound-smtp.us-east-1.amazonaws.com")
TIME_BETWEEN_EMAILS = 1800 # Every half hour

Thread.new do 
  loop do
    mut.synchronize do
      unless new_domains.empty?
        domains = []
        body = "<table border=\"1\"><thead><tr><th>Domain</th><th>Query</th></tr></thead><tbody>"
        new_domains.each do |domain|
          if domain['msg'] =~ /New domain observed: ([^ ]+) from query ([^ ]+)/
            domain_name = $1.to_s.gsub(".", "[.]")
            query = domain['msg'].split("from query ").last.gsub(".", "[.]") #$2.to_s.gsub(".", "[.]")
            body += "<tr><td>#{domain_name}</td><td>#{query}</td></tr>"
          else
            body += domain['msg'] + "\n"
          end
        end
  
        body += "</tbody></table>\n"
  
        new_domains.each do |domain|
          body += "<pre>" + JSON.pretty_unparse(domain) + "</pre><hr />"
        end
        emailer.send_alert_email("New Domains Observed (#{new_domains.length} domains)", body, "zeek@raptormail.net", "Zeek", "rvictory@raptormail.net", "Ryan Victory")
      end
      new_domains = []
    end
    sleep TIME_BETWEEN_EMAILS
  end
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