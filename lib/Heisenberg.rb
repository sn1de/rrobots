require_relative 'rrobots/robot.rb'

class Heisenberg

    include Robot

    def initialize *args, &block
        super
        @near_edge = false
        @last_hit = 0
        @turn_count = 0
        @near_count = 0
        @since_near_edge = 0
        @lock = 1
        @control = 0
        @velocity = 1 # -8..8
        @turn_amount = 1 # max is 10 degrees per tick, heading is 0 to 360
        @turn_direction = 1
        @gun_turn = 3
        @gun_direction = 1
        @overheated = false
        @weapon = 0.1 # 0.1 to 3
        @enemies_near = false
        @enemy_distance = 9999
    end

    def tick(events)
        update_status(events)
        weapons(events)
        move(events)
        radar(events)
        gun(events)
    end

    def update_status(events)
        @near_edge = is_near_border?
        @control = time % 100
        show_status

        if !events['robot_scanned'].empty?
            @enemy_distance = events['robot_scanned'].min.first
            @enemies_near = true
            @near_count = time 
            @lock = 1
        elsif time - @near_count > 50
            @enemies_near = false
            @lock = 1
        end

        @overheated = gun_heat > 0
            
    end

    def move(events)

        @last_hit = time unless events['got_hit'].empty?

        wounded = false
        if @last_hit && time - @last_hit < 10
            accelerate 8
            @turn_amount = 10
            wounded = true 
        elsif @near_edge and time > 100
            @since_near_edge = time + 20
            @turn_amount = rand(8..10)
        else
            if @control < 10
                stop
                turn_gun 1
            elsif time > @since_near_edge
                thrust rand(2..4)

                if rand(1..20) == 3
                    @turn_direction = - @turn_direction
                end
            else
                thrust rand(3..5)
                
                if time - @turn_count > 15 
                    @turn_direction = - @turn_direction
                    @turn_count = time
                end

            end
            @turn_amount = 1

        end

        if @control % 4 == 0 
            turn @lock * (@turn_amount * @turn_direction)
        end

        if wounded
            speak "You got me"
        elsif @overheated
            speak "Tread lightly"
        elsif @control > 35 and @control < 65
            speak "Say my name!"
        elsif @control > 25 and @control < 75
            speak "I am the one who knocks"
        else
            speak "I am the danger!"
        end
                
                
    end

    def radar(events)
        turn_radar @lock * (@gun_turn * @gun_direction)
    end

    def gun(events)
        if @control > 25 and @control < 75
            if @control % 10 == 0
                @gun_direction = - @gun_direction
            end
            turn_gun @lock * (@gun_turn * @gun_direction)
        end

    end

    def weapons(events)
        
        if !@enemies_near
            @weapon -= 0.4
            if @weapon <= 0
                if @control < 10 or @control > 90
                    @weapon = 0.0
                else
                    @weapon = 0.1
                end
            end
        else
            if @enemy_distance < 800
                @weapon = 3.0
            else
                @weapon = 1.0
            end
        end
        shoot @weapon
    end

    def shoot(n)
        if not @overheated and n > 0
            fire n
        else
            speak "Tread lightly"
        end
    end

    def thrust(n)
        if @control > 45 and @control < 55
            accelerate -n*2 
        else
            accelerate n 
        end
    end

    def is_near_border?
        x < 100 || y < 100 || x > battlefield_width - 100 || y > battlefield_height - 100
    end

    def yell(msg)
        if @control > 50
            say msg
        end
        puts msg
    end

    def speak(msg)
        if @control <= 50
            say msg
        end
    end

    def show_status
        puts "#{@control} turn=#{@turn_amount} near=#{is_near_border?} enemies_near=#{@enemies_near} enemy_distance=#{@enemy_distance}"
    end


end
