class World
    attr_reader :objs, :tiles, :dim, :bounds, :nonstatic, :width, :height,
        :tiles


    def initialize(args, screen_offset, w: 32, h: 32, dim: 16)
        @dim = dim
        @width = dim
        @height = dim
        @bounds = [w, h]
        @objs = Ordered_Tree.new()
        @tiles = {}
        @nonstatic = {}
        @static = :static
        @internal_offset = [0, 0]
        @world_size = [2560, 2560]

        args.outputs[@static].w = @world_size.x 
        args.outputs[@static].h = @world_size.y 

        w.times() do |x|
            h.times() do |y|
                @tiles[[x, y]] = {}

                args.outputs[@static].primitives << {
                    x: x * @dim, 
                    y: y * @dim, 
                    w: @width, 
                    h: @height, 
                    path: 'sprites/square/blue.png'
                }.sprite!
            end
        end
    end


    def valid_add(obj)
        x = obj.x
        y = obj.y

        return @tiles[[x, y]]
    end


    def add(obj)
        hit = []
        w_count = obj.w
        h_count = obj.h

        w_count.each() do |cur_w|
            h_count.each() do |cur_h|
                x = (obj.x.round + cur_w)
                y = (obj.y.round + cur_h)

                next if(!@tiles[[x,y]])
                 
                @tiles[[x, y]][obj.uid] = obj
                hit << [x, y]
            end
        end

        @nonstatic[obj.uid] = obj if(!obj.static)
        @objs << obj

        return hit
    end


    def delete(obj)
        w_count = (obj.w).round()
        h_count = (obj.h).round()
        
        w_count.each() do |cur_w|
            h_count.each() do |cur_h|
                x = obj.x.round + cur_w
                y = obj.y.round + cur_h
                
                next if(!@tiles.has_key?([x,y]) || 
                        !@tiles[[x,y]].has_key?(obj.type))

                @tiles[[x, y]].delete(obj.uid)
            end
        end

        @nonstatic.delete(obj.uid)
        @objs.delete(obj)
    end


    def get_by_uid(uid)
        return @objs[uid]
    end


    def update(obj, old_position)
        x = obj.x        
        y = obj.y 
        
        return if(x == old_position.x && y == old_position.y)

        delete({
            uid: obj.uid, 
            type: obj.type,
            x: old_position.x, 
            y: old_position.y, 
            w: obj.w, 
            h: obj.h,
            z: obj.z
        })
        return add(obj)
    end
   

    def render(args, screen_offset)
        _world_out = []
        _out = []

        _out << {
            x: 0, 
            y: 0, 
            w: 1280, 
            h: 740, 
            source_x: screen_offset.x,
            source_y: screen_offset.y,
            source_w: 1280,
            source_h: 740,
            path: @static
        }
        args.outputs[:update].transient!
        args.outputs[:update].w = @world_size.x 
        args.outputs[:update].h = @world_size.y

        @objs.values.each do |level|
            level.values.each do |obj|
                _world_out << {
                    x: obj.x * @dim,
                    y: obj.y * @dim,
                    w: obj.h * @dim,
                    h: obj.w * @dim,
                    path: obj.path
                }
            end
        end

        args.outputs[:update].sprites << _world_out

        _out << {
            x: 0, 
            y: 0, 
            w: 1280, 
            h: 740, 
            source_x: screen_offset.x,
            source_y: screen_offset.y,
            source_w: 1280,
            source_h: 740,
            path: :update 
        }

        return _out
    end


    def screen_to_world(pos)
        pos = [(pos.x / @dim).floor(), (pos.y / @dim).floor()]
    end


    def check_collisions(pos, w, h)
        _collisions = []

        w.each() do |_cur_w|
            h.each() do |_cur_h|
                _x = pos.x.round + _cur_w
                _y = pos.y.round + _cur_h

                if(@tiles[[_x, _y]] && @tiles[[_x, _y]].values.length > 0)
                    _collisions << @tiles[[_x, _y]].values
                elsif(!@tiles[[_x, _y]])
                    _collisions << nil 
                end
            end
        end       

        return _collisions
    end
end
