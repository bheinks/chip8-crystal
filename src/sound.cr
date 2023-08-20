require "crsfml/audio"

module Sound
    extend self

    def sine_wave(sample_rate : Int, time : Float, frequency : Float) : Int16
        ticks_per_cycle = sample_rate / frequency
        cycles = time / ticks_per_cycle
        radians = Math::TAU * cycles
        (INT16_MAX * Math.sin(radians)).to_i16
    end

    def generate_samples(sample_rate : Int, frequency : Float) : Slice(Int16)
        Slice.new(sample_rate) do |i|
            Sound.sine_wave(sample_rate, i.to_f64, frequency)
        end
    end

    class Stream < SF::SoundStream
        def initialize(channel_count : Int, sample_rate : Int, frequency : Float)
            super channel_count, sample_rate
            @samples = Sound.generate_samples(sample_rate, frequency)
        end

        def set_frequency(frequency : Float)
            @samples = Sound.generate_samples(self.sample_rate, frequency)
        end

        def on_get_data() : Slice(Int16)?
            status == SF::SoundSource::Playing ? @samples : nil
        end

        def on_seek(time_offset)
        end
    end
end
