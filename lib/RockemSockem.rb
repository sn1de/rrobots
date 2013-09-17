require_relative 'rrobots/robot.rb'

class RockemSockem
   include Robot

  def tick events

      
  

   if events['robot_scanned'].empty? 
     turn_gun 4
     fire 2
   else    
     fire 4
     say 'Pew Pew'
     turn 2
     
   end 
   
  @last_hit = time unless events['got_hit'].empty? 
  if @last_hit && time - @last_hit < 99
      say 'No, NOT THE FACE'
      fire 3
      accelerate 10
      
  elsif energy < 10
  say 'Womp Womp Womp'
  end
  
  end
end
  



