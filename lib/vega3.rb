require "Matrix"
require_relative "rrobots/robot.rb"

# when near border, spin and get a new centroid, then move away from it...

class Vega3
	
	include Robot
	
	SEARCH_SPEED = 15
	SEARCH_ERROR = 4
	
	LOW_FIRE_POWER = 0.1
	MID_FIRE_POWER = 0.3
	MAX_FIRE_POWER = 3 

	REGRESS_ORDER = 1 #linear

	DEG_TO_RAD = Math::PI / 180
	RAD_TO_DEG = 1 / Math::PI * 180

	SEARCH = 0
	FOUND = 1
	LOCKED = 2
	
	EAST = 0
	NORTH = 90
	WEST = 180
	SOUTH = 270

	FIND_RETRY_TIME = 20
	LOCK_RETRY_TIME = 20
	MAX_FIND_TRIES = 2
	LOCK_RADAR_TURN = 10
	#UPDATE_TURN_TIME = 50
	MAX_TURN = 10

	def initialize *args, &block
		super
		@sighted = false
		@hit = false
		@target_heading = 0
		@beta = 1

		@target_x = Array.new
		@target_y = Array.new

		@last_sighted = 0

		@target_vel = 0
		
		@random = Random.new

		@mode = SEARCH
		@lock_dir = 1

		@target_speed = 1

		@target_vel_x = 0
		@target_vel_y = 0

		@turning = false

		@current_turn = NORTH

		@centroid_x = 0
		@centroid_y = 0

		@current_min_x = 0
		@current_min_y = 0

		@found_at = 0

	end

	def getMinTurnDelta a, b
		(((a - b) + 180) % 360) - 180
	end

	def regress x, y, degree
		x_data = x.map { |xi| (0..degree).map { |pow| (xi ** pow).to_f } }
		mx = Matrix[*x_data]
		my = Matrix.column_vector(y)
  		((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
	end

	def modeStr mode
		case mode
			when SEARCH
				return "SEARCH"
			when FOUND
				return "FOUND"
			when LOCKED
				return "LOCKED"
		end
	end

	def clearTargets
		@target_x.clear
		@target_y.clear
	end

	def is_near_border?
    	case @current_turn
    		when 0
    			x > battlefield_width - 100
    		when 90
    			y < 100
    		when 180
    			x < 100
    		when 270
    			y > battlefield_height - 100
    	end
    end

    def make_turn
    	@current_turn = (@current_turn + 90) % 360
	end

	def calc_x distance
		(@x + distance * Math.cos((@radar_heading - SEARCH_SPEED / 2) * DEG_TO_RAD)).round
	end

	def calc_y distance
		(@y + distance * Math.sin((@radar_heading - SEARCH_SPEED / 2) * DEG_TO_RAD)).round
	end

	def tick events
		
		if @time == 0
			@field_center_x = @battlefield_width / 2
			@field_center_y = @battlefield_height / 2
		end

		@sighted = !events["robot_scanned"].empty?
		@hit = !events["got_hit"].empty?

		@time_since_last_sighted = @time - @last_sighted

		if @sighted

			events["robot_scanned"].each { |dist|
				@centroid_x = (@centroid_x + calc_x(dist.first)) / 2
				@centroid_y = (@centroid_y + calc_y(dist.first)) / 2
			}

			@min_dist = events["robot_scanned"].min.first
			
			@current_min_x = calc_x @min_dist
			@current_min_y = calc_y @min_dist

			if @target_x.empty? or @target_x.last != @current_min_x or @target_y.last != @current_min_y
				@target_x << @current_min_x
				@target_y << @current_min_y
				if @target_x.length > 1
					begin
						@betas = regress @target_x, @target_y, REGRESS_ORDER
					rescue
						puts "ahh"
					end
					@target_vel_x = (@target_x.last - @target_x.at(-2)) / @time_since_last_sighted
					@target_vel_y = (@target_y.last - @target_y.at(-2)) / @time_since_last_sighted
					@last_sighted = @time
				end
			end
		end
		
		if @target_x.length > 1 and @betas.length > 0
			@target_pos_x = @target_x.last + @target_vel_x * @time_since_last_sighted
			@target_pos_y = @betas[1] * @target_pos_x + @betas[0]
			alpha =  Math.atan2(@target_pos_y - @y, @target_pos_x - @x)
			alpha = (alpha > 0 ? alpha : (2 * Math::PI + alpha)) * 360 / (2 * Math::PI)
			@target_heading = alpha.round
		end

		case @mode
			when SEARCH
				if @sighted
					@mode = FOUND
					@found_at = @time
					@tries = 0
					@first = true
					#puts "Search Sight"
				end
			when FOUND
				if @sighted
					#puts "Found Sight"
					
					#@mode = LOCKED
					#@locked_at = @time
					#@sightings = 0

					#last_x = @target_x.last
					#last_y = @target_y.last
					#clearTargets()
					#@target_x << last_x
					#@target_y << last_y

					@lock_dir *= 1

				else
					if @time - @found_at > FIND_RETRY_TIME
						@tries += 1
						if @tries < MAX_FIND_TRIES
							@lock_dir *= -1
							@found_at = @time
						else
							@lock_dir *= -1
							@mode = SEARCH
						end
					end
				end
			when LOCKED
				if @sighted
					@sightings += 1
					#puts "Locked Sight"
				end
				if @time - @locked_at > LOCK_RETRY_TIME
					if @sightings == 0
						@mode = SEARCH
					else
						@sightings = 0
						@locked_at = @time
					end
				end
		end

		#puts modeStr @mode

		case @mode
			when SEARCH
				turn_gun @lock_dir * SEARCH_SPEED #+ @random.rand(SEARCH_ERROR) - SEARCH_ERROR / 2
				if @first
					@first = false
					turn_radar getMinTurnDelta(@gun_heading, @radar_heading)
				end
			when FOUND
				if @first
					@first = false
					turn_gun SEARCH_SPEED * -@lock_dir
				else
					turn_gun @lock_dir
				end
			when LOCKED
				delta = @time - @locked_at
				if delta < LOCK_RETRY_TIME / 2
					turn_radar -LOCK_RADAR_TURN
				else
					turn_radar LOCK_RADAR_TURN
				end
				#turn_gun getMinTurnDelta(@target_heading, @gun_heading)
		end

		if @time - @found_at == 0
			fire MAX_FIRE_POWER
		else
			fire @mode == FOUND ? MID_FIRE_POWER : LOW_FIRE_POWER
		end

		if is_near_border? or @hit #or @time % UPDATE_TURN_TIME == 0
			
			if @centroid_x == 0 and @centroid_y == 0
				@centroid_x = @current_min_x
				@centroid_y = @current_min_y
			end

			puts "#{@centroid_x}, #{@centroid_y}"

			vert_delta = @centroid_y - @field_center_y
			horz_delta = @centroid_x - @field_center_x 
			if vert_delta.abs < horz_delta.abs
				@current_turn = vert_delta < 0 ? SOUTH : NORTH
			else
				@current_turn = horz_delta < 0 ? EAST : WEST
			end

			@centroid_x = 0
			@centroid_y = 0

		end

		if @heading != @current_turn
			delta = @current_turn - @heading
			if delta > MAX_TURN
				turn MAX_TURN
			else
				turn delta
				@turning = false
				turn_gun getMinTurnDelta(@target_heading, @gun_heading)
			end
		end

		accelerate 1

	end
	
end