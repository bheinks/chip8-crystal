require "./chip8"

rom = File.read "IBM Logo.ch8"
emu = Chip8.new rom
emu.start