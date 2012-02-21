require_relative 'rrobots/robot.rb'

class Twitch
   include Robot

  def initialize 
    @passage_time = 0
  end
  
            
  def tick events   
      
   @passage_time = @passage_time + 1
   if @passage_time < 150 
     accelerate 8
   elsif @passage_time > 300
     @passage_time = 0
   else
     accelerate -8
   end
   
  # if @passage_time == 0
  #   turn_radar 2
  # elsif turn_radar 0
  # else @passage_time == 150
  #   turn_radar -2
  # end
     
   if time == 0 
     @passage_time = 0
   end
   
   if !events['got_hit'].empty? && energy.between?(1,40)
     say "That\'s starting to HURT"
   end
     
   if events['robot_scanned'].empty?  
     turn_gun 12
   else                               
     fire 1
     turn_gun -12
   end 
   
  end
end


