require "./constants"

class Cpu
    property sound_timer = 0_u16
    property delay_timer = 0_u16

    def initialize(memory : Memory)
        @memory = memory
        @stack = Array(Word).new
    end
end