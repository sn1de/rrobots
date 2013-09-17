require 'rrobots'

class GirlDuck
   include Robot

  def tick events
    turn_radar 1 if time == 0
    turn_gun 30 if time < 3
    accelerate 1
    turn 2
    fire 3 unless events['robot_scanned'].empty? 
  end
end

def gun_targeting
    	if @locked_on
    		@lock_on_count -= 1
    		if @lock_on_count == 0
    			@locked_on = false
    			@turn_amount = @turn_amount * -1
    		end
    	turn_gun @turn_amount/5

    	else
    		turn_gun @turn_amount
    	end
    end
    
	def scan events
    if events['robot_scanned'].empty?
    increase_radar_scan
    else
    decrease_radar_scan
    @min_distance = events['robot_scanned'].min.first
  end
    @rt = if @radar_turned
    -@radar_scan 
  else
    @radar_scan
  end if @radar_scan.abs < @max_radar_scan - 0.1
    @radar_turned = !@radar_turned
    @rt
  end
	
	def increase_radar_scan
    @radar_scan *= 1.5
    @radar_scan = [@radar_scan, @max_radar_scan].min
  end

  def decrease_radar_scan
    @radar_scan *= 0.5
    @radar_scan = [@radar_scan, @min_radar_scan].max
  end
    
 def move1
		accelerate @my_speed
		if is_near_border? && @wait < 1
		   @my_speed = speed * -1
		   @wait = 100
		end
		@wait -= 1
		
		turn @my_turn
		if (time > 0 && (time % 7) == 0)
			@my_turn += 1
			if @my_turn > 10
				@my_turn = -10
			end
		end
    end
	
	
  
  