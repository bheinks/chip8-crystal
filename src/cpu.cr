require "bitfield"

require "./constants"

# Split opcode into four nibbles
class Opcode < BitField(Word)
    num fourth, 4
    num third, 4
    num second, 4
    num first, 4
end

class Cpu
    property sound_timer = 0_u8
    property delay_timer = 0_u8

    def initialize(memory : Array(Byte), video_memory : Array(Array(Bool)), keymap : Array(Bool))
        @memory = memory
        @video_memory = video_memory
        @keymap = keymap
        @stack = Array(Word).new
        @PC = 0x200_u16             # Program Counter
        @I = 0_u16                  # Index register
        @V = Array(Byte).new 16, 0  # General-purpose registers
    end

    def cycle
        decode
    end

    private def fetch : Opcode?
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

        case opcode.first
        when 0x0
            case opcode.fourth
            when 0x0 # Clear display
                clear_display
            when 0xE # Subroutine return
                @PC = @stack.pop
            end
        when 0x1 # Jump
            @PC = opcode.value & 0x0FFF
        when 0x2 # Subroutine call
            @stack.push @PC
            @PC = opcode.value & 0x0FFF
        when 0x3 # if Vx == NN
            if @V[opcode.second] == (opcode.value & 0x00FF) && @PC < @memory.size + 1
                @PC += 2
            end
        when 0x4 # if Vx != NN
            if @V[opcode.second] != (opcode.value & 0x00FF) && @PC < @memory.size + 1
                @PC += 2
            end
        when 0x5 # if Vx == Vy
            if @V[opcode.second] == @V[opcode.third] && @PC < @memory.size + 1
                @PC += 2
            end
        when 0x6 # Vx = NN
            @V[opcode.second] = (opcode.value & 0x00FF).to_u8
        when 0x7 # Vx += NN
            sum = @V[opcode.second].to_u16 + (opcode.value & 0x00FF).to_u16

            # Check for overflow
            if sum > UINT8_MAX
                sum -= UINT8_MAX
            end

            @V[opcode.second] = sum.to_u8
        when 0x8
            case opcode.fourth
            when 0x0 # Vx = Vy
                @V[opcode.second] = @V[opcode.third]
            when 0x1 # Vx |= Vy
                @V[opcode.second] |= @V[opcode.third]
            when 0x2 # Vx &= Vy
                @V[opcode.second] &= @V[opcode.third]
            when 0x3 # Vx ^= Vy
                @V[opcode.second] ^= @V[opcode.third]
            when 0x4 # Vx += Vy
                sum = @V[opcode.second].to_u16 + @V[opcode.third].to_u16

                # Check for overflow
                if sum > UINT8_MAX
                    sum -= UINT8_MAX
                    @V[0xF] = 1
                else
                    @V[0xF] = 0
                end

                @V[opcode.second] = sum.to_u8
            when 0x5 # Vx -= Vy
                # Subtract registers as Int16 so as to avoid OverflowError
                difference = @V[opcode.second].to_i16 - @V[opcode.third].to_i16

                # Check for underflow
                if difference < 0
                    difference += UINT8_MAX
                    @V[0xF] = 0
                else
                    @V[0xF] = 1
                end

                @V[opcode.second] = difference.to_u8
            when 0x6 # Vx >>= Vy
                @V[0xF] = @V[opcode.second] & 0x1
                @V[opcode.second] >>= 1
            when 0x7 # Vx = Vy - Vx
                # Subtract registers as Int16 so as to avoid OverflowError
                difference = @V[opcode.third].to_i16 - @V[opcode.second].to_i16

                # Check for underflow
                if difference < 0
                    difference += UINT8_MAX
                    @V[0xF] = 0
                else
                    @V[0xF] = 1
                end

                @V[opcode.second] = difference.to_u8
            when 0xE # Vx <<= Vy
                @V[0xF] = (@V[opcode.second] & 0x80) >> 7
                @V[opcode.second] <<= 1
            end
        when 0x9 # if Vx != Vy
            if @V[opcode.second] != @V[opcode.third] && @PC < @memory.size + 1
                @PC += 2
            end
        when 0xA # I = NNN
            @I = opcode.value & 0x0FFF
        when 0xB # PC = V0 + NNN
            @PC = @V[0].to_u16 + (opcode.value & 0x0FFF)
        when 0xC # Vx = rand() & NN
            @V[opcode.second] = Random.rand(UINT8_MAX).to_u8 & (opcode.value & 0x00FF)
        when 0xD # draw(Vx, Vy, N)
            draw @V[opcode.second], @V[opcode.third], opcode.fourth.to_u8
        when 0xE
            case opcode.value & 0x00FF
            when 0x9E # if (key() == Vx)
                if @keymap[@V[opcode.second]] && @PC < @memory.size + 1
                    @PC += 2
                end
            when 0xA1 # if (key() != Vx)
                if !@keymap[@V[opcode.second]] && @PC < @memory.size + 1
                    @PC += 2
                end
            end
        when 0xF
            case opcode.value & 0x00FF
            when 0x07 # Vx = get_delay()
                @V[opcode.second] = @delay_timer
            when 0x0A # Vx = get_key()
                key = @keymap.index { |k| true }
                if key.nil?
                    @PC -= 2
                else
                    @V[opcode.second] = key.to_u8
                end
            when 0x15 # delay_timer(Vx)
                @delay_timer = @V[opcode.second]
            when 0x18 # sound_timer(Vx)
                @sound_timer = @V[opcode.second]
            when 0x1E # I += Vx
                @I += @V[opcode.second]
            when 0x29 # I = sprite_addr[Vx]
                @I = FONT_ADDRESS.to_u16 + (5 * @V[opcode.second])
            when 0x33 # setBCD(Vx)
                value = @V[opcode.second]

                @memory[@I+2] = value % 10 # Ones place
                value //= 10

                @memory[@I+1] = value % 10 # Tens place
                value //= 10

                @memory[@I] = value % 10 # Hundreds place
            when 0x55 # reg_dump(Vx, &I)
                (0..opcode.second).each do |i|
                    @memory[@I+i] = @V[i]
                end
            when 0x65 # reg_load(Vx, &I)
                (0..opcode.second).each do |i|
                    @V[i] = @memory[@I+i]
                end
            end
        end
    end

    private def clear_display
        @video_memory.each do |row|
            row.map! { |_| false }
        end
    end

    private def draw(x : Byte, y : Byte, n : Byte)
        @V[0xF] = 0
        (0...n).each do |row|
            sprite = @memory[@I + row]
            (0...8).each do |col|
                y_index = (y + row) % DISPLAY_HEIGHT
                x_index = (x + col) % DISPLAY_WIDTH

                sprite_pixel = (sprite & (0x80 >> col)) > 0 ? true : false
                screen_pixel = @video_memory[y_index][x_index]
                if sprite_pixel
                    if screen_pixel
                        @V[0xF] = 1
                    end

                    screen_pixel ^= sprite_pixel
                    @video_memory[y_index][x_index] = screen_pixel
                end
            end
        end
    end
end