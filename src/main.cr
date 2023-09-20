require "option_parser"

require "./chip8"
require "./constants"

scale = 30
delay = 0.0
file = ""

parser = OptionParser.parse do |parser|
    parser.banner = "Usage: #{NAME} [-s <scale>] [-d <delay>] <file>"

    parser.on "file", "ROM file" {}

    parser.on "-s scale", "--scale=scale", "Window scale (default: #{scale})" do |_scale| 
        begin
            scale = _scale.to_i
        rescue ArgumentError
            puts parser
            exit
        end
    end

    parser.on "-d delay", "--delay=delay", "Instruction delay (default: #{delay})" do |_delay|
        begin
            delay = _delay.to_f
        rescue ArgumentError
            puts parser
            exit
        end
    end

    parser.on "-v", "--version", "Show version" do
        puts "#{NAME} #{VERSION}"
        exit
    end

    parser.on "-h", "--help", "Show help" do
        puts parser
        exit
    end

    parser.missing_option do |_|
        puts parser
        exit
    end

    parser.invalid_option do |_|
        puts parser
        exit
    end
end

file = ARGV.pop?
if file.nil? || file.empty?
    puts parser
    exit
end

if !File.exists?(file)
    puts "File not found: #{file}"
    exit
end

emu = Chip8.new scale, delay, File.read file
emu.start