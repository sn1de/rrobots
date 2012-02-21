require_relative 'rrobots/robot.rb'

class Sector

  attr_accessor :name
  attr_accessor :range
  attr_accessor :enemies
  attr_accessor :closest_enemy
  attr_accessor :gun_direction
  
  def initialize(sector_range, sector_name)
    @name = sector_name
    @range = sector_range
    @fire_to = range.first
    @gun_direction = 1
    @enemies = false
  end
  
  
  def fire_next
    @fire_ret = @fire_to
    if @fire_to == range.last
      @gun_direction = -1
    elsif @fire_to == range.first
      @gun_direction = 1
    end
    @fire_to = @fire_to + @gun_direction
    @fire_ret
  end

end

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
    @sectors = [
      Sector.new(0..19, "alpha"),
      #Sector.new(10..19, "bravo"),
      Sector.new(20..39, "charlie"),
      #Sector.new(30..39, "delta"),
      Sector.new(40..59, "echo"),
      #Sector.new(50..59, "foxtrot"),
      Sector.new(60..79, "golf"),
      #Sector.new(70..79, "hotel"),
      Sector.new(80..99, "irene"),
      #Sector.new(90..99, "j"),
      Sector.new(100..119, "kilo"),
      #Sector.new(110..119, "lima"),
      Sector.new(120..139, "m"),
      #Sector.new(130..139, "n"),
      Sector.new(140..159, "oscar"),
      #Sector.new(150..159, "p"),
      Sector.new(160..180, "q"),
      #Sector.new(170..180, "r")
      ]
      
    @gun_in_position = false
    @scan_sector_idx = 0
    @target_sector = nil
    @fire_counter = 0
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
#        when :fight
#          fight(events)
        when :roam
          roam(events)
#        when :scan
#          scan(events)
        when :radar_to_sector
          radar_to_sector
        when :check_enemies
          check_enemies
        when :unleash_heck
          unleash_heck
        else 
          say "I'm lost!"
      end
    end
    dump_scan
    dump_sectors
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
      @next_actions_queue << :radar_to_sector
    else
      turn (heading - @due_west >= 10) ? -10 : @due_west - heading
      @next_actions_queue << :position
    end
  end
  
  def aim(events)
    puts "Assuming firing position... move from #{gun_heading} to #{@target_sector.range.first}"
    
    if gun_heading == @target_sector.range.first
      @next_actions_queue << :unleash_heck
    else
      t = @target_sector.range.first - gun_heading
      puts "Turning gun by #{t}"
      turn_gun(t)
      @next_actions_queue << :aim
    end
  end

  def unleash_heck
    puts "Firing at heading #{gun_heading}"
    fire(0.3)
    turn_gun(@target_sector.fire_next - gun_heading)
    @fire_counter += 1
    if @fire_counter < 50
      @next_actions_queue << :unleash_heck
    else
      @fire_counter = 0
      @next_actions_queue << :radar_to_sector
    end
  end
  
  def fight(events)
    turn_radar 1
    if !events['robot_scanned'].empty?
      @next_actions_queue << :roam
      @next_actions_queue << :fight
    else
      dump_scan
      if speed >= 2
        stop
      elsif speed < 2
        @next_actions_queue << :roam
      end
      fire(0.1)
      #turn_gun(@sectors[@gun_sector_idx].fire_next - gun_heading)
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
  
  def scan(events)
    if radar_heading < 120 && radar_heading > 60
      turn_radar(radar_heading - 120)
    else
      turn_radar(60)
    end
    @next_actions_queue << :scan
  end

  def radar_to_sector
    puts "radar_to_sector radar_heading=#{radar_heading} move to #{@sectors[@scan_sector_idx].range.first}"
    if radar_heading == @sectors[@scan_sector_idx].range.first
      scan_sweep = @sectors[@scan_sector_idx].range.last - @sectors[@scan_sector_idx].range.first
      puts "radar set, turning to scan by #{scan_sweep}"
      turn_radar(scan_sweep)
      @next_actions_queue << :check_enemies
    else
      puts "moving radar by #{@sectors[@scan_sector_idx].range.first - radar_heading}"
      distance_from_sector = @sectors[@scan_sector_idx].range.first - radar_heading 
      turn_radar distance_from_sector > 60 ? 60 : distance_from_sector
      @next_actions_queue << :radar_to_sector
    end 
  end
  
  def check_enemies
    puts "Checking for enemies in sector #{@scan_sector_idx}"
    if !events['robot_scanned'].empty?
      closest = 99999
      for distance in events['robot_scanned'].flatten.sort
        if distance < closest
          closest = distance
        end
      end
      @sectors[@scan_sector_idx].enemies = true
      @sectors[@scan_sector_idx].closest_enemy = closest
    else
      # clear the sector
      @sectors[@scan_sector_idx].enemies = false
      @sectors[@scan_sector_idx].closest_enemy = 0
    end
    advance_scan_sector
    if @scan_sector_idx == 0
      set_target_sector
      if @target_sector == nil
        @next_actions_queue << :radar_to_sector
      else
        @next_actions_queue << :aim
      end
    else
      @next_actions_queue << :radar_to_sector 
    end
  end
  
  def advance_scan_sector
    if @scan_sector_idx < @sectors.size - 1
      @scan_sector_idx += 1
    else
      @scan_sector_idx = 0
    end
    puts "Now scanning #{@scan_sector_idx}"
  end
  
  def set_target_sector
    @target_sector = nil

    @sectors.each { | sector |
      puts "Checking sector #{sector.name} enemies #{sector.enemies} closest #{sector.closest_enemy}"
      if sector.enemies == true
        if @target_sector == nil
          @target_sector = sector
        else
          if @target_sector.closest_enemy > sector.closest_enemy
            @target_sector = sector
          end
        end
      end
    }

    if @target_sector == nil
      puts "No enemy activity detected"
    else
      puts "Targeting locked in on sector #{@target_sector.name}"
    end
  end
  
  def dump_scan
    #puts "Dumping Scan:"
    #puts events
    #distance = events['robot_scanned'].flatten.min
    for distance in events['robot_scanned'].flatten.sort
      puts "SpaceInvader scanned distance = #{distance}"
    end
    
#    if event = events['robot_scanned'].pop
#      puts "got something"
#      dist = event.first
#      puts "distance = #{dist}"
#    else
#      #puts "got nothing"
#    end
  end
  
  def dump_sectors
    puts "Sectors:" 
    @sectors.each_with_index { | sector, i |
      puts "Sector #{i} enemies #{sector.enemies} closest #{sector.closest_enemy}"
    }    
  end
end
