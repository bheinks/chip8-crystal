require "crsfml"

require "./constants"
require "./cpu"
require "./memory"
require "./sound"
require "./window"

class Chip8
    def initialize
        @memory = Memory.new
        @cpu = Cpu.new @memory
        @stream = Sound::Stream.new CHANNEL_COUNT, SAMPLE_RATE, Waveform::Sine, Note::A
        
        # Set up window
        @window = Window.new SF::VideoMode.new(800, 600), "CHIP-8"
        @window.framerate_limit = FRAMERATE

        # Initialize font
        FONT.each_with_index do |c, i|
            @memory[FONT_ADDRESS + i] = c
        end
    end

    def start
        spawn cpu_loop
        event_loop
    end

    private def cpu_loop
    end

    private def event_loop
        while @window.open?
            # Process GUI events
            #@window.process_events
            while event = @window.poll_event
                case event
                when SF::Event::Closed
                    @window.close
                when SF::Event::KeyPressed
                    # TODO: user input
                end
            end
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
end