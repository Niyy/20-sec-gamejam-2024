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
        w_count = (obj.w / @dim).ceil() + 1
        h_count = (obj.h / @dim).ceil() + 1
        
        w_count.each() do |cur_w|
            h_count.each() do |cur_h|
                x = obj.x + cur_w
                y = obj.y + cur_h

                if(@tiles.has_key?([x, y]) && !@tiles[[x, y]].has_key?(obj.type))
                    @tiles[[x, y]][obj.type] = {} 
                end

                puts "world -> adding #{[x, y]}"
                @tiles[[x, y]][obj.type][obj.uid] = obj
            end
        end

        @nonstatic[obj.uid] = obj if(!obj.static)
        @objs << obj
    end


    def delete(obj)
        w_count = (obj.w / @dim).ceil() + 1
        h_count = (obj.h / @dim).ceil() + 1
        
        puts "delete count #{[w_count, h_count]}"
        
        w_count.each() do |cur_w|
            h_count.each() do |cur_h|
                x = obj.x + cur_w
                y = obj.y + cur_h

                puts "deleting #{[x, y]}"

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
        
        puts "new pos #{[x, y]} old pos #{[old_position.x, old_position.y]}"
        return if(x == old_position.x && y == old_position.y)

        delete({
            uid: obj.uid, 
            type: obj.type,
            x: old_position.x, 
            y: old_position.y, 
            w: obj.w, 
            h: obj.h
        })
        add(obj)
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
            {
                x: obj.x * @dim,
                y: obj.y * @dim,
                w: obj.w,
                h: obj.h,
                path: obj.path,
                primitive_marker: :sprite
            }
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


    def tile_filled?(position, type, passing_qty)
        return true if(!(@tiles[position] && @tiles[position][type]))

        return @tiles[position][type].values.length <= passing_qty
    end


    def screen_to_world(pos)
        pos = [(pos.x / @dim).floor(), (pos.y / @dim).floor()]
    end
end
