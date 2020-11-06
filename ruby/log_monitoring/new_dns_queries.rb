require_relative '../lib/emailer'
require "json"

mut = Mutex.new
new_domains = []
new_user_agents = []
new_connections = []
new_devices = []

host_mappings = {}

if File.exists?("~/host_mappings.tsv")
  IO.read("~/host_mappings.tsv").split("\n").each do |line|
    parts = line.chomp.split("\t")
    host_mappings[parts[0]] = parts[1]
  end
end

emailer = Emailer.new("inbound-smtp.us-east-1.amazonaws.com")
TIME_BETWEEN_EMAILS = ENV['EMAIL_INTERVAL'].nil? ? 3600 : ENV['EMAIL_INTERVAL'].to_i 

Thread.new do 
  loop do
    mut.synchronize do
      body = ""

      unless new_domains.empty?
        domains = []
        new_domains.uniq! {|x| x["msg"]}
        body += "<h2>New Domains</h2><table border=\"1\"><thead><tr><th>Domain</th><th>Query</th><th>Source IP</th><th>Source Name</th></tr></thead><tbody>"
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
  
        #new_domains.each do |domain|
        #  body += "<pre>" + JSON.pretty_unparse(domain) + "</pre><hr />"
        #end
      end

      unless new_user_agents.empty?
        body += "<h2>New User-Agents</h2><table border=\"1\"><thead><tr><th>User-Agent</th><th>Host</th><th>Source IP</th><th>Source Name</th></tr></thead><tbody>"
        new_user_agents.each do |user_agent|
          if user_agent['msg'] =~ /New User-Agent: (.+) connecting to host (.+)/
            ua = $1.to_s
            host = $2.to_s
            body += "<tr><td>#{ua}</td><td>#{host}</td><td>#{user_agent["id.orig_h"]}</td><td>#{user_agent['host_name']}</td></tr>"
          else
            body += user_agent['msg'] + "\n"
          end
        end
        body += "</tbody></table>\n"
      end

      unless new_devices.empty?
        body += "<h2>New Devices</h2><table border=\"1\"><thead><tr><th>MAC</th><th>DHCP Host Name</th><th>Discovered Host Name</th></tr></thead><tbody>"
        new_devices.each do |new_device|
          if new_device['msg'] =~ /New Device: (.+) with name (.+)/
            mac = $1.to_s
            host = $2.to_s
            body += "<tr><td>#{mac}</td><td>#{host}</td><td>#{new_device['host_name']}</td></tr>"
          else
            body += new_device['msg'] + "\n"
          end
        end
        body += "</tbody></table>\n"
      end

      unless new_connections.empty?
        body += "<h2>New Connection Pairs</h2><table border=\"1\"><thead><tr><th>Orig_h</th><th>Resp_h</th><th>Resp_p</th><th>Source Name</th></tr></thead><tbody>"
        new_connections.each do |connection|
          if connection['msg'] =~ /New Orig_h Resp_h Pair: (.+)/
            parts = $1.to_s.split(" -> ")
            orig_h = parts[0]
            resp_h = parts[1]
            body += "<tr><td>#{orig_h}</td><td>#{resp_h}</td><td>#{connection["id.resp_p"]}</td><td>#{connection['host_name']}</td></tr>"
          else
            body += connection['msg'] + "\n"
          end
        end
        body += "</tbody></table>\n"
      end

      if body != ""
        emailer.send_alert_email("New Things Observed (#{new_domains.length} domains)", body, "zeek@raptormail.net", "Zeek", "rvictory@raptormail.net", "Ryan Victory")
      end
      new_domains = []
      new_user_agents = []
      new_connections = []
      new_devices = []
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

  # Try to grab the name of the system from the current day's dhcp logs
  source_ip = data["id.orig_h"]

  system_name = data["dhcp_host_name"] || host_mappings[source_ip] || "<unknown>"

  if system_name == "<unknown>"
    current_dhcp_entry = `grep -h '#{source_ip}' /data/corelight/spool/logger/dhcp.log | head -1`
    if current_dhcp_entry.length < 1
      log_day = data["ts"].split("T").first
      current_dhcp_entry = `grep -h '#{source_ip}' /data/corelight/logs/#{log_day}/dhcp*.log | head -1`
    end

    if current_dhcp_entry.length > 1
      dhcp_entry = JSON.parse(current_dhcp_entry)
      system_name = dhcp_entry["host_name"].to_s
    end
  end

  data["host_name"] = system_name

  if data["note"] == "DNSMonitor::DNS_New_Domain"
    next if data["id.orig_h"] == "192.168.3.143"
    puts "Queued #{data['msg']} from source host #{system_name}"
    mut.synchronize do
      new_domains.push(data)
    end
  elsif data["note"] == "NewConnectionMonitor::NewOrigRespPair"
    puts "Queued #{data['msg']} from source host #{system_name}"
    mut.synchronize do
      new_connections.push(data)
    end
  elsif data["note"] == "NewUserAgentMonitor::NewUserAgent"
    puts "Queued #{data['msg']} from source host #{system_name}"
    mut.synchronize do
      new_user_agents.push(data)
    end
  elsif data["note"] == "NewDeviceMonitor::NewDevice"
    puts "Queued #{data['msg']} from source host #{system_name}"
    mut.synchronize do
      new_devices.push(data)
    end
  end
end