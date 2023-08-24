require "crsfml/system"

class Memory(T)
    def initialize(*args, **kwargs)
        @data = Array(T).new *args, **kwargs
        @mutex = SF::Mutex.new
    end

    def [](address) : T
        @mutex.lock
        value = @data[address]
        @mutex.unlock
        return value
    end

    def []=(address, value : T)
        @mutex.lock
        @data[address] = value
        @mutex.unlock
    end

    def size
        @data.size
    end
end

class VideoMemory < Memory(Bool)
    def initialize(width : Int32, height : Int32)
        super width * height, false
        @width = width
        @height = height
    end

    def set(x, y, value : Bool)
        self[@width * y + x] = value
    end

    def get(x, y) : Bool
        self[@width * y + x]
    end

    def clear
        @mutex.lock
        @data.map! { |_| false }
        @mutex.unlock
    end
end