class Game < View
    attr_accessor :world


    def initialize(args)
        self.args = args
        @screen_offset = [0, 0]
        @world = World.new(args, @screen_offset, w: 40, h: 40, dim: 16)
        @cursor_pos = [0, 0]

        pawn = Pawn.new(
            w: 1, 
            h: 1,
            z: 0,
            path: 'sprites/circle/yellow.png',
            static: false
        )
        pawn.target([10, 10])
        puts "first pawn #{pawn.uid}"
        
        @world.add(pawn)
#
#        pawn = Pawn.new(
#            x: 15,
#            y: 15,
#            w: 1, 
#            h: 1, 
#            z: 0,
#            path: 'sprites/circle/yellow.png',
#            static: false
#        )
#        pawn.target([10, 10])
#        puts "second pawn #{pawn.uid}"
#        
#        @world.add(pawn)

        puts 'world loaded'
    end


    def tick()
        input()
        output() 
        update()

        return nil
    end


    def input()
        _collisions_mouse = []
        _mouse_pos = [inputs.mouse.x, inputs.mouse.y]
        _mouse_pos.x += @screen_offset.x
        _mouse_pos.y += @screen_offset.y
        @cursor_pos = @world.screen_to_world(_mouse_pos)

        _collisions_mouse = @world.check_collisions(@cursor_pos, 2, 2)

        if(inputs.mouse.click)
            puts "on tile: #{_collisions_mouse} length #{_collisions_mouse.length}"
        end

        if(
            inputs.mouse.button_left && 
            @world.tiles[@cursor_pos] &&
            _collisions_mouse.length <= 0

        )
            @world.add(Structure.new(
                x: @cursor_pos.x, 
                y: @cursor_pos.y, 
                w: 2, 
                h: 2, 
                path: 'sprites/square/green.png',
                primitive_marker: :sprite
#                tags: {indestructable: 1}
            ))            
        end

        @screen_offset.x += 10 if(inputs.keyboard.key_down.d)
        @screen_offset.x -= 10 if(inputs.keyboard.key_down.a && 
                                  @screen_offset.x - 10 > 0)
    end


    def output()
        outputs[:view].transient!
#        outputs[:view].sprites << @world.objs.branches
#        outputs.sprites << {x: 0, y: 0, w: 1280, h: 720, path: :view}
        outputs.sprites << @world.render(args, @screen_offset)
        outputs.labels << {x: 0, y: 700, text: @cursor_pos, r: 0}
    end


    def update()
        @world.nonstatic.values.each() do |obj|
            obj.update(state.tick_count, @world)
        end
    end
end
