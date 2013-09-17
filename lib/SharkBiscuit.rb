require_relative 'rrobots/robot.rb'

class SharkBiscuit
	include Robot
	
	def tick events

		if events.empty?
			turn_gun 12
		else 
			p events
		end

		if !events['robot_scanned'].empty? 
			# scanned something 
			target_found
		end

		if !events['got_hit'].empty?
			evade
			shoot
		end


    end
 
    def target_found 
    	#turn 5
    	puts "found a target!!!"
    	p "gun heading #{gun_heading}"
    	shoot
    	turn_gun -12
    	accelerate(1)

     end

    def evade 
    	p "evading, speed is #{speed}, x is #{x}, y is #{y} and size #{size}"
    	if x <= size
    		turn -10
    	else
    		turn 10
    	end

 		if speed < 5 
 			accelerate 1
 		elsif speed > 5
 			stop
 		else
 			accelerate 1
 		end 
    	turn_gun 5
    end

    def shoot
    	p "gun heat #{gun_heat}"
    	if @gun_heat < 0.25
    		velocity = 2
    	elsif @gun_heat > 0.75 
    		velocity = 0.5
    	else
    		velocity = 0.1
    	end
    	fire(velocity)
    	p "fire #{velocity}"
    end

    def hit 
    	#turn 1
    	#turn_gun 30
    	#turn_gun(30)
    	stop
    	accelerate -1
    	p "ouch"
    end
 end