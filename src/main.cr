require "option_parser"

require "./chip8"
require "./constants"

scale = 0
delay = 0.0
rom = ""

parser = OptionParser.parse do |parser|
    parser.banner = "Usage: #{NAME} <scale> <delay> <rom>"

    parser.on "-v", "--version", "Show version" do
        puts "#{NAME} #{VERSION}"
        exit
    end

    parser.on "-h", "--help", "Show help" do
        puts parser
        exit
    end

    parser.on "scale", "Window scale" { |_scale| scale = _scale.to_i }
    parser.on "delay", "Instruction delay" { |_delay| delay = _delay.to_f }
    parser.on "rom", "ROM file" { |_rom| rom = _rom }
end

if !scale || !delay || rom.empty?
    puts parser
    exit
end

emu = Chip8.new scale, delay, File.read rom
emu.start