require "io"

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
num_bytes = 536870912
if !File.exists?(filename)
    puts "Building an empty database"
    File.open(filename, "wb") do |f|
        num_bytes.times do
            f.write_byte 0
        end
    end
end

num_writes = 1000000
puts "Benchmarking #{num_writes} reads"
begin_time = Time.utc.to_unix_f
File.open(filename, "r+") do |f|
    num_writes.times do 
        ip = random_ip
        #puts "Observing #{ip}"
        #observe(ip, f)
        has_seen?(ip, f)
    end
end
end_time = Time.utc.to_unix_f
time_taken = end_time - begin_time
puts "Took #{time_taken} seconds to read #{num_writes} IPs"
puts "That's #{num_writes / time_taken} reads per second"