class Pawn < DR_Object
    attr_accessor :path_start, :path_max_range, :task
    attr_reader :target, :path_cur, :path_end, :path_start, :col_list


    def initialize(**argv)
        super
        
        @task = nil
        @speed = 60
        @perc = 2.0
        @faction = argv.faction

        # Pathing
        clear_path()
        @col_list = []
    end


    def update(tick_count, world)
        create_path(world.tiles)
        move_lerp(tick_count, world)
    end


    def clear_path()
        @path_max_range = 0
        @target = nil
        @path_end = nil
        @path_parents = {}
        @path_queue = Min_Tree.new()
        @path_cur = []
        @last_position = [@x, @y]
    end


    def path_queue_add(tiles, cur, dif, trail_end = {x: -1, y: -1}, queue = [], 
        parents = {}
    )
        next_step = {
            x: cur.x + dif.x, 
            y: cur.y + dif.y, 
            uid: [cur.x + dif.x, cur.y + dif.y]
        }
        step_dist = sqr(trail_end.x - next_step.x) + 
            sqr(trail_end.y - next_step.y) 
        
        if(
            tiles.has_key?([next_step.x, next_step.y]) &&
            !parents.has_key?(next_step.uid) && 
            (
                assess(tiles, next_step, cur, dif)# || 
#                combat_assess(tiles, next_step, cur, dif) || 
#                (
#                    trail_end.x == cur.x &&
#                    trail_end.y == cur.y
#                )
            )
        )
            queue << next_step.merge({z: step_dist}) 
            parents[next_step.uid] = cur 
            return next_step
        end
    end


    def path_current_add_single(cur, world, tiles, tasks = {})
        move_points = [
            [1, 0],
            [0, 1],
            [-1, 0],
            [0, -1],
            [1, 1],
            [-1, 1],
            [1, -1],
            [-1, -1]
        ]

        while(!move_points.empty?())
            delta = move_points.sample()
            move_points.delete(delta)

            next_step = {
                x: cur.x + delta.x, 
                y: cur.y + delta.y, 
                uid: [cur.x + delta.x, cur.y + delta.y]
            } 
            
            if(
                (tasks == nil || tasks.unassigned[next_step.uid] == nil) &&
                (tasks == nil || tasks.assigned[next_step.uid] == nil) &&
                assess(tiles, next_step, cur, delta)
            )
                @trail << next_step
                @trail_end = next_step if(@trail_end == nil)
                @found = @trail_end if(@found == nil)
                return
            end
        end
    end



    def create_path(tiles)
        return if(@path_end || @target.nil?())

        _path_found = nil

        @path_queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        @path_parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}
        
        15.times() do |i|
            if(!@path_queue.empty?() && @path_found.nil?())
                cur = @path_queue.pop()

                if(in_range(cur, @target) <= @path_max_range * @path_max_range)
                    _path_found = cur 
                    break
                end
                
                path_queue_add(tiles, cur, [0, 1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [0, -1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [1, 0], @target, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [-1, 0], @target, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [1, 1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [1, -1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [-1, 1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(tiles, cur, [-1, -1], @target, @path_queue, 
                               @path_parents)
            end
        end

        if(!_path_found.nil?())
            @path_cur.clear()
            @path_end = _path_found
            child = _path_found 

            while(@path_parents[child.uid].uid != child.uid)
                @path_cur << child 
                child = @path_parents[child.uid]
            end

            @next_step = @path_cur.pop()
            return
        end
    end


    def move(tick_count, world)
        if(@next_step && @next_step && tick_count % @speed == 0)
            @last_x = @x
            @last_y = @y
            @x = @next_step.x
            @y = @next_step.y

            @next_step = @path_cur.pop()
            @col_list = world.update(self, {x: @last_x, y: @last_y})
        end
    end


    def move_lerp(tick_count, world)
        if(@next_step && @last_x && @last_y && @perc <= 1.0)
            @x = @last_x + ((@next_step.x - @last_x) * @perc)
            @y = @last_y + ((@next_step.y - @last_y) * @perc)
            @perc += 0.005
            new_col_list = world.update(self, {x: @last_x, y: @last_y})
            @col_list = new_col_list if(new_col_list)
        end


        
        if(@perc >= 1.0)
            if(@next_step)
                @x = @next_step.x
                @y = @next_step.y
            end

            @last_x = @x
            @last_y = @y
            @next_step = @path_cur.pop()
            @perc = 0
            added_col_tiles = world.update(
                self, 
                {x: @last_x, y: @last_y}, 
                @col_list
            )
        end
    end


    def assess(tiles, next_pos, original_tile, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                (
                    !tiles[next_pos.uid][:structure] ||
                    tiles[next_pos.uid][:structure].values.length == 0 || 
                    tiles[next_pos.uid][:structure].values[0].passable 
                ) &&
                (
                    tiles.has_key?([next_pos.x, original_tile.y]) && 
                    (
                        !tiles[[next_pos.x, original_tile.y]][:structure] ||
                        tiles[[next_pos.x, original_tile.y]][:structure].values.length == 0 ||
                        tiles[[next_pos.x, original_tile.y]][:structure].values[0].passable 
                    ) || 
                    tiles.has_key?([original_tile.x, next_pos.y]) && 
                    (
                        !tiles[[original_tile.x, next_pos.y]][:structure] ||
                        tiles[[original_tile.x, next_pos.y]][:structure].values.length == 0 ||
                        tiles[[original_tile.x, next_pos.y]][:structure].values[0].passable 
                    ) 
                )
            )
        end
        
        return (
            tiles.has_key?(next_pos.uid) && 
            (
                !tiles[next_pos.uid][:structure] || 
                tiles[next_pos.uid][:structure].values.length == 0 ||
                tiles[next_pos.uid][:structure].values[0].passable 
            ) &&
            tiles[next_pos.uid][:pawn].nil?()
        )
    end


    def will_collide?(tiles, next_col_list)
        has_collided? = false

        next_col_list.each() do |tile|
            continue if()

            has_collided? = true if(!tiles.has_key?(tile) || 
                tiles[tile].keys.length > 0)
        end

        return has_collided?
    end


    def combat_assess(tiles, next_pos, og, dir = [0, 0])
        if(dir.x != 0 && dir.y != 0)
            return (
                tiles.has_key?(next_pos.uid) && 
                tiles[next_pos.uid][:ground].nil?() &&
                tiles[next_pos.uid][:pawn].nil?() &&
                tiles.has_key?([next_pos.x, og.y]) && 
                tiles[[next_pos.x, og.y]][:ground].nil?() && 
                tiles[[next_pos.x, og.y]][:pawn].nil?() && 
                tiles.has_key?([og.x, next_pos.y]) && 
                tiles[[og.x, next_pos.y]][:ground].nil?() &&
                tiles[[og.x, next_pos.y]][:pawn].nil?()
            )
        end

        return (
            (
                tiles[next_pos.uid] &&
                tiles[next_pos.uid][:ground] &&
                @enemies.has_key?(tiles[next_pos.uid][:ground].
                                                       faction.
                                                       to_s.
                                                       to_sym) 
            ) || (
                tiles[next_pos.uid] &&
                tiles[next_pos.uid][:pawn] &&
                @enemies.has_key?(tiles[next_pos.uid][:pawn].
                                                       faction.
                                                       to_s.
                                                       to_sym)
            )
        )
    end


    def get_task(tasks)
        return if(@target || @task)
        
        clear_path()
        @task = tasks.pop()
    end


    def assess_task(world, tiles)
        return if(!@task || !@target)

        if(@target.check_end_state(@task))
            @task = nil
            @target = nil
            clear_path()
            return
        end

        @task.requirments.entries.each() do |req, need|
            if(req == :has)
                @target = @task.target if(@inventory[need.type])
                @target = world.find(need) if(!@inventory[need.type])
            end
        end
    end


    def check_end_state(state)
        state.entries.each() do |entry, value|
            return false if(entry == :supply && value != @supply)
        end

        return true 
    end


    def tile()
        return [@x, @y]
    end


    def target=(value)
        clear_path()
        @target = value
    end


    def in_range(cur, pos)
        range = (cur.x - pos.x) * (cur.x - pos.x) +
                (cur.y - pos.y) * (cur.y - pos.y)

        return range
    end


    def copy()
        return Pawn.new(
            x: @x,
            y: @y,
            z: @z,
            w: @w,
            h: @h,
            g: @g,
            b: @b,
            tick: @tick,
            primitive_marker: @primitive_marker,
            type: @type
        )
    end
end
