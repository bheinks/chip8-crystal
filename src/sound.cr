require "crsfml/audio"

require "./constants"

module Sound
    extend self

    def sine_sample(sample_rate : Int, time : Float, frequency : Float) : Int16
        ticks_per_cycle = sample_rate / frequency
        cycles = time / ticks_per_cycle
        radians = cycles * Math::TAU
        (Math.sin(radians) * INT16_MAX).to_i16
    end

    def sawtooth_sample(sample_rate : Int, time : Float, frequency : Float) : Int16
        ticks_per_cycle = sample_rate / frequency
        cycles = time / ticks_per_cycle
        (2 * (cycles - (0.5 + cycles).floor()) * INT16_MAX).to_i16
    end

    def square_sample(sample_rate : Int, time : Float, frequency : Float) : Int16
        ticks_per_cycle = sample_rate // frequency
        cycles = time.to_i % ticks_per_cycle
        cycles < (ticks_per_cycle / 2) ? INT16_MAX : 0_i16
    end

    def generate_samples(sample_rate : Int, frequency : Float, waveform : Waveform) : Slice(Int16)
        Slice.new(sample_rate) do |i|
            case waveform
            when Waveform::Sine
                Sound.sine_sample(sample_rate, i.to_f64, frequency)
            when Waveform::Sawtooth
                Sound.sawtooth_sample(sample_rate, i.to_f64, frequency)
            when Waveform::Square
                Sound.square_sample(sample_rate, i.to_f64, frequency)
            else
                raise "Unsupported waveform type: #{waveform}"
            end
        end
    end

    class Stream < SF::SoundStream
        def initialize(channel_count : Int, sample_rate : Int, waveform : Waveform, frequency : Float64)
            super channel_count, sample_rate
            @frequency = frequency
            @waveform = waveform
            @samples = Sound.generate_samples(sample_rate, frequency, waveform)
        end

        def set_frequency(frequency : Float)
            @samples = Sound.generate_samples(self.sample_rate, frequency, @waveform)
        end

        def set_waveform(waveform : Waveform)
            @samples = Sound.generate_samples(self.sample_rate, @frequency, waveform)
        end

        def on_get_data() : Slice(Int16)?
            p @samples[20]
            status == SF::SoundSource::Playing ? @samples : nil
        end

        def on_seek(time_offset)
        end
    end
end
