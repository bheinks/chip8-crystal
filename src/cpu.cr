require "bitfield"

require "./constants"
require "./memory"

# Split opcode into four nibbles
class Opcode < BitField(Word)
    num fourth, 4
    num third, 4
    num second, 4
    num first, 4
end

class Cpu
    property sound_timer = 0_u16
    property delay_timer = 0_u16

    def initialize(memory : Memory(Byte), video_memory : VideoMemory)
        @memory = memory
        @video_memory = video_memory

        @stack = Array(Word).new
        @PC = 0x200_u16             # Program Counter
        @I = 0_u16                  # Index register
        @V = Array(Byte).new 16, 0  # General-purpose registers

        private @execution_time = Time::Span.new
        private @instructions_per_second = 0
    end

    def process_events
        @execution_time = Time::Span.new
        while true
            @execution_time += Time.measure do
                decode
                @instructions_per_second += 1
                sleep INSTRUCTION_DELAY
            end

            if @execution_time >= 1.second
                #p "#{@instructions_per_second}/sec"
                @instructions_per_second = 0
                @execution_time = Time::Span.new
            end
        end
    end

    def fetch : Opcode?
        if @PC + 1 > @memory.size
            return nil
        end
        # Fetch next two bytes in memory and increment program counter
        opcode = Opcode.new @memory[@PC].to_u16 << 8 | @memory[@PC + 1].to_u16
        @PC += 2
        opcode
    end

    def decode
        opcode = fetch
        if opcode.nil?
            return
        end

        p opcode.value.to_s(16)

        case opcode.first
        when 0x0
            case opcode.fourth
            when 0x0 # Clear display
                clear_display
            when 0xE # Return
                @pc = @stack.pop
            end
        when 0x1 # Jump
            @PC = opcode.value & 0x0FFF
        when 0x2
        when 0x3
        when 0x4
        when 0x5
        when 0x6 # Vx = NN
            @V[opcode.second] = (opcode.value & 0x00FF).to_u8
        when 0x7 # Vx += NN
            @V[opcode.second] += (opcode.value & 0x00FF).to_u8
        when 0x8
        when 0x9
        when 0xA # I = NNN
            @I = opcode.value & 0x0FFF
        when 0xB
        when 0xC
        when 0xD
            x = @V[opcode.second] % DISPLAY_WIDTH
            y = @V[opcode.third] % DISPLAY_HEIGHT
            n = opcode.fourth.to_u8
            draw x, y, n
        when 0xE
        when 0xF
        end
    end

    def clear_display
        @video_memory.clear
    end

    def draw(x : Byte, y : Byte, n : Byte)
        @V[0xF] = 0
        (0...n).each do |row|
            sprite = @memory[@I + row]
            (0...8).each do |col|
                sprite_pixel = (sprite & (0x80 >> col)) > 0 ? true : false
                screen_pixel = @video_memory.get(x + col, y + row)

                if sprite_pixel
                    if screen_pixel
                        @V[0xF] = 1
                    end

                    screen_pixel ^= sprite_pixel
                    @video_memory.set(x + col, y + row, screen_pixel)
                end
            end
        end
    end
end