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
        body = "<table border=\"1\"><thead><tr><th>Domain</th><th>Query</th><th>Source IP</th><th>Source Name</th></tr></thead><tbody>"
        new_domains.each do |domain|
          if domain['msg'] =~ /New domain observed: ([^ ]+) from query ([^ ]+)/
            domain_name = $1.to_s.gsub(".", "[.]")
            query = domain['msg'].split("from query ").last.gsub(".", "[.]") #$2.to_s.gsub(".", "[.]")
            body += "<tr><td>#{domain_name}</td><td>#{query}</td><td>#{domain["id.orig_h"]}</td><td>#{domain['host_name']}</td></tr>"
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
  # Try to grab the name of the system from the current day's dhcp logs
  source_ip = data["id.orig_h"]
  system_name = "<unknown>"
  current_dhcp_entry = `grep -h '#{source_ip}' /data/corelight/spool/logger/dhcp.log | head -1`
  if current_dhcp_entry.length < 1
    log_day = data["ts"].split("T").first
    current_dhcp_entry = `grep -h '#{source_ip}' /data/corelight/logs/#{log_day}/dhcp*.log | head -1`
  end

  if current_dhcp_entry.length > 1
    dhcp_entry = JSON.parse(current_dhcp_entry)
    system_name = dhcp_entry["host_name"].to_s
  end

  data["host_name"] = system_name

  puts "Queued #{data['msg']} from source host #{system_name}"
  mut.synchronize do
    new_domains.push(data)
  end
end