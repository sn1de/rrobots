require_relative 'rrobots/robot.rb'

class SharkBiscuit
	include Robot
	
	def tick events
        # p "time is #{time}"
		if events.empty?
			adjust_gun -1
		else 
			# p events
		end

		if !events['robot_scanned'].empty? 
			# scanned something 
			adjust_gun 1
		end

		if !events['got_hit'].empty?
			evade
		end

        shoot
        
        if energy <= 10
            say "I'm going towards the light, goodbye cruel world"
        end


    end

    def adjust_gun direction 
        turn_gun 8 * direction 
        # p "gun heading #{gun_heading}"

    end
 
    def evade 
    	# p "evading, heading #{heading}, speed is #{speed}, x is #{x}, y is #{y} and size #{size}"
         if time % 2
                turn 10
            else
                turn -10
            end

 		if speed < 5 
 			accelerate 1
 		elsif speed > 5
 			stop
 		else
 			accelerate 1
 		end 
    end

    def shoot
        velocity = 0.1
    	fire(velocity)
    end

 end