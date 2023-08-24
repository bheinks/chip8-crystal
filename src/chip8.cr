require "crsfml"

require "./constants"
require "./cpu"
require "./memory"
require "./sound"
require "./window"

class Chip8
    def initialize(rom : String)
        @memory = Memory(Byte).new MEMORY_SIZE, 0_u8
        @video_memory = VideoMemory.new DISPLAY_WIDTH, DISPLAY_HEIGHT
        @cpu = Cpu.new @memory, @video_memory
        @stream = Sound::Stream.new CHANNEL_COUNT, SAMPLE_RATE, Waveform::Sine, Note::A
        
        # Set up window
        @window = SF::RenderWindow.new SF::VideoMode.new(DISPLAY_WIDTH * DISPLAY_SCALE, DISPLAY_HEIGHT * DISPLAY_SCALE), "CHIP-8"
        @window.framerate_limit = FRAMERATE

        # Threading
        @cpu_thread = SF::Thread.new(->cpu_loop)

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
        @cpu_thread.launch
        event_loop
    end

    private def cpu_loop
        @cpu.process_events
    end

    private def event_loop
        while @window.open?
            # Process GUI events
            #@window.process_events
            while event = @window.poll_event
                case event
                when SF::Event::Closed
                    @window.close
                when SF::Event::KeyReleased
                    case event.code
                    when .num1?
                    when .num2?
                    when .num3?
                    when .num4?
                    when .q?
                    when .w?
                    when .e?
                    when .r?
                    when .a?
                    when .s?
                    when .d?
                    when .f?
                    when .z?
                    when .x?
                    when .c?
                    when .v?
                    end
                end
            end

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
        end
    end

    private def draw_sprites
        (0...DISPLAY_HEIGHT).each do |y|
            (0...DISPLAY_WIDTH).each do |x|
                if @video_memory.get(x, y)
                    pixel = SF::RectangleShape.new SF.vector2(DISPLAY_SCALE, DISPLAY_SCALE)
                    pixel.position = SF.vector2 x * DISPLAY_SCALE, y * DISPLAY_SCALE
                    @window.draw pixel
                end
            end
        end
    end
end