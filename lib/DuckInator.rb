require_relative 'rrobots/robot.rb'

class DuckInator
	include Robot

	def tick events
		turn -10
		attack

		if energy <= 15
     		say "Curse you, Perry the Platypus!"
   		end

   		if game_over
   			say "Behold my new evil scheme, the Duck-Inator!"
   		end
	end

	def attack
		if !events['robot_scanned'].empty?
			fire 1.5

			if time % 3
				turn_gun 4
			else
				turn_gun -8
			end
    	else
    		turn 5
    		accelerate 8
    		fire 0.1
    	end
	end
end