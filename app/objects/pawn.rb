class Pawn < DR_Object
    attr_accessor :path_start, :path_max_range, :task, :dim
    attr_reader :path_cur, :path_end, :path_start, :col_list, :perc,
                :next_step, :last_x, :last_y


    def initialize(**argv)
        super
        
        @task = nil
        @speed = 0.014
        @perc = 2.0
        @faction = argv.faction
        @state = :idle
        @fighting = nil
        @phys_defence = 0

        # Pathing
        clear_path()
        @col_list = []
    end


    def update(tick_count, world)
        create_path(world, world.tiles) if(@state == :create_path)
        move(tick_count, world) if(@state == :move)
    end


    def target(new_target = nil)
        return @target if(!new_target)

        clear_path()
        @path_queue << {x: @x.round(), y: @y.round(), z: 0, uid: [@x, @y]}
        @path_parents[[@x, @y]] = {x: @x, y: @y, z: 0, uid: [@x, @y]}
        @target = new_target

        @state = :create_path
    end


    def clear_path()
        @path_max_range = 0
        @target = nil
        @path_end = nil
        @path_parents = {}
        @path_queue = Min_Tree.new()
        @path_cur = []
        @last_position = [@x, @y]
        @next_step = nil

        @state = :idle
    end


    def path_queue_add(world, tiles, cur, dif, trail_end = {x: -1, y: -1}, queue = [], 
        parents = {}
    )
        _next_step = {
            x: cur.x + dif.x, 
            y: cur.y + dif.y, 
            uid: [cur.x + dif.x, cur.y + dif.y]
        }
        _step_dist = sqr(trail_end.x - _next_step.x) + 
            sqr(trail_end.y - _next_step.y) 
        _collisions = world.check_collisions(_next_step, @w, @h)
        
        if(
            tiles.has_key?([_next_step.x, _next_step.y]) &&
            !parents.has_key?(_next_step.uid) && 
            _collisions.length <= 0 #&&
#            (
#                !_collisions[0] || 
#                _collisions[0].uid == @uid
#            )
        )
            queue << _next_step.merge({z: _step_dist}) 
            parents[_next_step.uid] = cur 
            return _next_step
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



    def create_path(world, tiles)
    # For a new path to be created the clear_path func should be called and then
    # you need to assign the target variable. target(new_target)
    # should automate this.
        return if(@path_end || @target.nil?())

        _path_found = nil
        
#        @path_queue << {x: @x, y: @y, z: 0, uid: [@x, @y]} 
        
        
        15.times() do |i|
            if(!@path_queue.empty?() && @path_found.nil?())
                cur = @path_queue.pop()

                if(in_range(cur, @target) <= @path_max_range * @path_max_range)
                    _path_found = cur 
                    break
                end
                
                path_queue_add(world, tiles, cur, [0, 1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(world, tiles, cur, [0, -1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(world, tiles, cur, [1, 0], @target, @path_queue, 
                               @path_parents)
                path_queue_add(world, tiles, cur, [-1, 0], @target, @path_queue, 
                               @path_parents)
                path_queue_add(world, tiles, cur, [1, 1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(world, tiles, cur, [1, -1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(world, tiles, cur, [-1, 1], @target, @path_queue, 
                               @path_parents)
                path_queue_add(world, tiles, cur, [-1, -1], @target, @path_queue, 
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
            @last_x = @x
            @last_y = @y
            @perc = 0
            @state = :move
            return
        end
    end


    def move(tick_count, world)
        next_state = {}

        return if(!(@next_step && @last_x && @last_y))

        next_state = {
            x: @last_x + ((@next_step.x - @last_x) * @perc),
            y: @last_y + ((@next_step.y - @last_y) * @perc),
            w: @w,
            h: @h,
            type: @type,
            uid: @uid
        }

        @x = @last_x + ((@next_step.x - @last_x) * @perc)
        @y = @last_y + ((@next_step.y - @last_y) * @perc)

        if(@perc <= 1.0)
            @perc += @speed

            new_col_list = world.update(
                self, 
                {x: @last_x, y: @last_y, uid: @uid, z: @uid}
            )
            @col_list = new_col_list if(new_col_list)
        end

        if(@perc >= 1.0)
            if(@next_step)
                next_state.x = @next_step.x
                next_state.y = @next_step.y
            end

            @last_x = @next_step.x
            @last_y = @next_step.y 
            @next_step = @path_cur.pop()
            @perc = 1.0 - @perc
            @col = world.update(
                self, 
                {x: @last_x, y: @last_y, uid: @uid, z: @uid}
            )

            if(@next_step)

                _collisions = world.check_collisions(@next_step, @w, @h)
                
                if(_collisions.length > 0)
                   _nxt_fight = pick_fight(_collisions)

                   @fighting = _nxt_fight.target if(_nxt_fight)
                   target(@target) if(!_nxt_fight)
                elsif(@target && _collisions.length > 0)
                    target(@target)
                end
            end
        end
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


    def fight(world, tick_count)
         
    end


    def pick_fight(_collisions)
        _fight_priority = Min_Tree.new()
        
        _collisions.each() do |_obj|
            _priority = 100

            next if(_obj.tag[:indestructable])

            _priority -= 50 if(_obj.type == :pawn)

            _fight_priority << {target: _obj, z: _priority}
        end

        return _fight_priority.pop() 
    end
end
