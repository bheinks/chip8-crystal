require "./constants"

class Memory
    getter data : Array(Byte)

    def initialize
        @data = Array(Byte).new MEMORY_SIZE, 0_u8
    end

    def [](address) : Byte
        @data[address]
    end

    def []=(address, value : Byte)
        @data[address] = value
    end
end