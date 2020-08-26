Dir.glob("./*.intel").each do |path|
    filename = File.basename(path)
    output_file = File.open("./cleaned/#{filename}", "w")
    File.open(path, "r") do |f|
        notice_column = 4
        while line = f.gets
            parts = line.split("\t")
            if line[0] == "#"
                parts.each_with_index do |x, i|
                    if x == "meta.do_notice"
                        notice_column = i - 1
                    end
                end
            else
                parts[notice_column] = "T"
            end
            output_file.puts parts.join("\t")
        end
    end
    output_file.close
end