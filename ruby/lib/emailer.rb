require "net/smtp"

class Emailer
    def initialize(smtp_server)
        @smtp_server = smtp_server
    end

    def send_alert_email(subject, body, from_address, from_name, to_address, to_name)
        message = <<MESSAGE_END
From: #{from_name} <#{from_address}>
To: #{to_name} <#{to_address}>
MIME-Version: 1.0
Content-type: text/html
Subject: #{subject}

#{body}
MESSAGE_END

        Net::SMTP.start(@smtp_server) do |smtp|
            smtp.send_message(message, from_address, to_address)
        end
    end
end