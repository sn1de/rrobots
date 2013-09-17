require_relative 'rrobots/robot.rb'

class TryBot
   include Robot

  def initialize
   @rapid_fire = 1 
   @last_seen = 1
   @turn_speed = 3
   #@direction = -1
   #@height = battlefield_height 
   #@width = battlefield_width 
  end

  def tick events
    turn_radar 5 if time == 0
    fire 3 unless events['robot_scanned'].empty? 
    turn_gun 10

    @rapid_fire = 0 if @rapid_fire.nil?
    @last_seen = 0 if @last_seen.nil?
    @turn_speed  = 3 if @turn_speed.nil?

    if time - @last_seen > 100
      @turn_speed *= -1
      @last_seen = time
    end

    turn @turn_speed

    if( @rapid_fire > 0 )
      fire 0.86
      turn_gun -(@turn_speed / @turn_speed) *2
      @rapid_fire = @rapid_fire - 1
    else
      turn_gun @turn_speed * 2.75
    end

    @last_hit = time unless events['got_hit'].empty?
    if @last_hit && time - @last_hit < 20
      accelerate(-1)
    else
      #turn_gun 30
      #turn_radar 60
      #turn 10
      accelerate 3
    end
      
    if( !events['robot_scanned'].empty? )
      @turn_speed *= -1
      @last_seen = time
      @rapid_fire = 3 
      turn_radar 15 if time == 0
      turn_gun 5 if time == 0
      fire 3.0
    end
  end
end

	
