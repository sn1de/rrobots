require_relative 'rrobots/robot.rb'

class SpaceInvader
  include Robot

  def initialize
    puts "Initializing Space Invader"
    @action_queue = [
      :head_down
    ]
    @next_actions_queue = []
    @current_phase = 0
    @due_north = 90
    @due_east = 0
    @due_west = 180
    @due_south = 270
    
    @roam_accel = 1
  end
  
  
  def tick events
    
    while !@action_queue.empty?
      case @action_queue.pop
        when :head_down
          head_down(events)
        when :travel_down
          travel_down(events)
        when :position
          position(events)
        when :aim
          aim(events)
        when :fight
          fight(events)
        when :roam
          roam(events)
        else 
          say "I'm lost!"
      end
    end
    
    @action_queue = @next_actions_queue
    @next_actions_queue = []
  end
  
  def head_down(events)
    say "Heading for solid ground..."
    if heading == @due_south
      say "Ready to head out!"
      @next_actions_queue << :travel_down
    elsif heading < @due_south
      say "Turning left..."
      turn (@due_south - heading >= 10) ? 10 : @due_south - heading
      @next_actions_queue << :head_down
    else
      say "Turning right..."
      d = @due_south - heading
      turn (d <= -10) ? -10 : d
      @next_actions_queue << :head_down
    end
  end
  
  def travel_down(events)
    # check to see if we've reahed the bottom
    if y < battlefield_height - size
      say "Underway..."
      accelerate(1)
      @next_actions_queue << :travel_down
    elsif speed == 0
      @next_actions_queue << :position
    else
      stop
      @next_actions_queue << :travel_down
    end
  end
  
  def position(events)
    say "Positioning..."
    if heading == @due_west
      @next_actions_queue << :aim
    else
      turn (heading - @due_west >= 10) ? -10 : @due_west - heading
      @next_actions_queue << :position
    end
  end
  
  def aim(events)
    say "Assuming firing position..."
    
    if gun_heading == @due_north
      @next_actions_queue << :fight
    else
      t = (gun_heading - @due_north >= 30) ? -30 : @due_north - gun_heading
      turn_gun(t)
      @next_actions_queue << :aim
    end
  end
  
  def fight(events)
    if !events['got_hit'].empty?
      puts "Taking fire"
    end
    
    if !events['robot_scanned'].empty?
      puts "No scanned"
      @next_actions_queue << :roam
      @next_actions_queue << :fight
    else
      if speed >= 2
        stop
      elsif speed < 2
        @next_actions_queue << :roam
      end
      fire(1)
      @next_actions_queue << :fight
    end
  end
  
  def roam(events)
    if x >= battlefield_width - size - 5
      @roam_accel = 1
    elsif x <= size
      @roam_accel = -1
    end
    
    accelerate(@roam_accel)
  end

end
