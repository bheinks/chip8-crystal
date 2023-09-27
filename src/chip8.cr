require "crsfml"
require "crsfml/system"

require "./constants"
require "./cpu"
require "./sound"

class Chip8
    def initialize(scale : Int32, delay : Float64, rom : String)
        @scale = scale
        @delay = delay.milliseconds
        @memory = Array(Byte).new MEMORY_SIZE, 0_u8
        @video_memory = Array(Array(Bool)).new(DISPLAY_HEIGHT) { Array.new DISPLAY_WIDTH, false }
        @keymap = Array(Bool).new 16, false
        @cpu = Cpu.new @memory, @video_memory, @keymap
        @stream = Sound::Stream.new CHANNEL_COUNT, SAMPLE_RATE, Waveform::Sine, Note::A
        @window = SF::RenderWindow.new SF::VideoMode.new(DISPLAY_WIDTH * @scale, DISPLAY_HEIGHT * @scale), NAME
        @window.framerate_limit = 700

        # Initialize font
        FONT.each_with_index do |c, i|
            @memory[FONT_ADDRESS + i] = c
        end

        # Load ROM
        offset = 0
        rom.each_byte do |b|
            @memory[ROM_ADDRESS + offset] = b
            offset += 1
        end
    end

    def start
        while @window.open?
            process_events
            @cpu.cycle
            clear_keymap

            # Update window
            @window.clear SF::Color::Black
            draw_sprites
            @window.display

            # Update sound timer
            if @cpu.sound_timer > 0
                if @stream.status != SF::SoundSource::Playing
                    @stream.play
                end
                @cpu.sound_timer -= 1
            else
                @stream.stop
            end

            # Update delay timer
            if @cpu.delay_timer > 0
                @cpu.delay_timer -= 1
            end
        end
    end

    private def process_events
        while event = @window.poll_event
            case event
            when SF::Event::Closed
                @window.close
            when SF::Event::KeyPressed
                case event.code
                when .num1?
                    key_pressed(0)
                when .num2?
                    key_pressed(0x1)
                when .num3?
                    key_pressed(0x2)
                when .num4?
                    key_pressed(0x3)
                when .q?
                    key_pressed(0x4)
                when .w?
                    key_pressed(0x5)
                when .e?
                    key_pressed(0x6)
                when .r?
                    key_pressed(0x7)
                when .a?
                    key_pressed(0x8)
                when .s?
                    key_pressed(0x9)
                when .d?
                    key_pressed(0xA)
                when .f?
                    key_pressed(0xB)
                when .z?
                    key_pressed(0xC)
                when .x?
                    key_pressed(0xD)
                when .c?
                    key_pressed(0xE)
                when .v?
                    key_pressed(0xF)
                end
            end
        end
    end

    private def key_pressed(keycode : Byte)
        @keymap[keycode] = true
    end

    private def clear_keymap
        @keymap.map! { |_| false }
    end

    private def draw_sprites
        (0...DISPLAY_HEIGHT).each do |y|
            (0...DISPLAY_WIDTH).each do |x|
                if @video_memory[y][x]
                    pixel = SF::RectangleShape.new SF.vector2(@scale, @scale)
                    pixel.position = SF.vector2 x * @scale, y * @scale
                    @window.draw pixel
                end
            end
        end
    end
end