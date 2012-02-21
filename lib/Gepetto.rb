require 'rrobots/robot'
require 'rrobots/battlefield'
require 'rrobots/explosion'
require 'rrobots/bullet'
require 'rrobots/robot_runner'
require 'rrobots/numeric'

class Gepetto
   include Robot

  def tick events
  	(dist = events['robot_scanned']).empty?
    if events['robot_scanned'].empty?
    	accelerate 8
    	turn 2
    	turn_gun 4
    else 
    	turn_gun -12
    	if (dist.first.first / 2).to_i <= 400
    		fire 1
    		(dist = events['robot_scanned']).empty?
      		say 'Enemy spotted ' + (dist.first.first / 2).to_i.to_s + ' pixels away!'
    	else
    		fire 0.2
    		say 'I\'m coming for YOU!'
    	end
    	accelerate -5
    	turn 0
	end
  
    	@last_hit = time unless events['got_hit'].empty? 
		if @last_hit && time - @last_hit < 1
      	accelerate(8)
      	turn 1
      	say 'OUCH! Son of a Duck!'
    	end
	end
end
