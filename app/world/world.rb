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
        w_count = (obj.w / @dim).floor() + 2
        h_count = (obj.h / @dim).floor() + 2
        
        w_count.each() do |cur_w|
            h_count.each() do |cur_h|
                x = (obj.x - 1 + cur_w).round
                y = (obj.y - 1 + cur_h).round

                next if(!@tiles.has_key?([x,y]))

                if(@tiles.has_key?([x, y]) && !@tiles[[x, y]].has_key?(obj.type))
                    @tiles[[x, y]][obj.type] = {} 
                end
                 
                @tiles[[x, y]][obj.type][obj.uid] = obj
                hit << [x, y]
            end
        end

        @nonstatic[obj.uid] = obj if(!obj.static)
        @objs << obj

        return hit
    end


    def delete(obj)
        w_count = (obj.w / @dim).ceil() + 1
        h_count = (obj.h / @dim).ceil() + 1
        
        w_count.each() do |cur_w|
            h_count.each() do |cur_h|
                x = obj.x + cur_w
                y = obj.y + cur_h
                
                next if(!@tiles.has_key?([x,y]) || 
                        !@tiles[[x,y]].has_key?(obj.type))

                @tiles[[x, y]][obj.type].delete(obj.uid)
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
            h: obj.h
        })
        return add(obj)
    end
   

    def render(args, screen_offset)
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

        args.outputs[:update].sprites << @objs.values.map() do |obj|
            out = []
            out << obj.col_list.map do |col|
                {
                    x: col.x * @dim, 
                    y: col.y * @dim, 
                    w: @dim, 
                    h: @dim, 
                    path: 'sprites/square/red.png'
                }
            end
            out << {
                x: obj.x * @dim,
                y: obj.y * @dim,
                w: obj.w,
                h: obj.h,
                path: obj.path,
                primitive_marker: :sprite
            }
            out
        end
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


    def collid?(obj)
        
    end
end
