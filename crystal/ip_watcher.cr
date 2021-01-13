require "io"
require "compress/gzip"

def random_ip
    "#{rand(255) + 1}.#{rand(255) + 1}.#{rand(255) + 1}.#{rand(255) + 1}"
    #"2.3.4.5"
end

def ip_to_int(ip : String)
    w, x, y, z = ip.split(".").map {|x| x.to_i}
    (16777216_i64 * w) + (65536_i64 * x) + (256_i64 * y) + z
end

def set_bit(input : UInt8, bit_num : UInt8, value : UInt8)
    mask = 1 << bit_num
    return (input & ~mask) | ((value << bit_num) & mask) 
end

def is_set?(input : UInt8, bit_num : UInt8) 
    mask = 2**bit_num
    input & mask == mask
end

def observe(ip, file)
    ip_num = ip_to_int(ip)
    byte_num = (ip_num // 8)
    bit_num = (ip_num % 8).to_u8
    file.seek(byte_num, IO::Seek::Set)
    current_value = file.read_byte
    if current_value
        file.seek(byte_num, IO::Seek::Set)
        file.write_byte(set_bit(current_value, bit_num, 1))
    end
end

def has_seen?(ip, file)
    ip_num = ip_to_int(ip)
    byte_num = ip_num // 8
    bit_num = (ip_num % 8).to_u8
    file.seek(byte_num, IO::Seek::Set)
    current_value = file.read_byte
    if current_value
        is_set?(current_value, bit_num)
    else
        false
    end
end

filename = "ip_db.bin"
#f = IO::Memory.new(1)
num_bytes = 536870912
if !File.exists?(filename)
    puts "Building an empty database"
    output_io = File.open(filename, "wb")
    #output_file = Compress::Gzip::Writer.new(output_io)
    num_bytes.times do
        output_io.write_byte 0
    end
    #output_file.close
    output_io.close
end
output_io = File.open(filename, "r+")
#output_file = Compress::Gzip::Writer.new(output_io)

puts "Observing IPs"
ARGF.each_line do |line|
    next if line[0] == '#'
    parts = line.split("\t")
    next if parts[2].includes?(":")
    observe(parts[2], output_io)
    next if parts[4].includes?(":")
    observe(parts[4], output_io)
end

#output_file.close
output_io.close
