require "crsfml"

require "./constants"

class Window < SF::RenderWindow
    def initialize(*args, **kwargs)
        super *args, **kwargs
        @pixels = Array(Array(Bool)).new(32) { Array.new 64, false }
    end

    def process_events
        while event = poll_event
            case event
            when SF::Event::Closed
                close
            when SF::Event::KeyPressed
                # TODO: user input
            end
        end
        display
    end
end