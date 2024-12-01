class Game < View
    attr_accessor :world


    def initialize(args)
        self.args = args
        puts 'hello my good sir.'
        @screen_offset = [0, 0]
        @world = World.new(args, @screen_offset, w: 40, h: 40, dim: 8)
        @cursor_pos = [0, 0]

        pawn = Pawn.new(
            w: 32, 
            h: 32, 
            path: 'sprites/circle/yellow.png',
            static: false
        )
        pawn.target = [10, 10]
        puts "first pawn #{pawn.uid}"
        
        @world.add(pawn)

        pawn = Pawn.new(
            x: 15,
            y: 15,
            w: 32, 
            h: 32, 
            path: 'sprites/circle/yellow.png',
            static: false
        )
        pawn.target = [10, 10]
        puts "second pawn #{pawn.uid}"
        
        @world.add(pawn)

        puts 'world loaded'
    end


    def tick()
        input()
        output() 
        update()

        return nil
    end


    def input()
        mouse_pos = [inputs.mouse.x, inputs.mouse.y]
        mouse_pos.x += @screen_offset.x
        mouse_pos.y += @screen_offset.y
        @cursor_pos = @world.screen_to_world(mouse_pos)

        if(inputs.mouse.click)
            puts "screen #{[inputs.mouse.x, inputs.mouse.y]}, pos #{@cursor_pos}"
        end


        if(inputs.mouse.button_left && @world.valid_add(@cursor_pos) && @world.collid?)
            @world.add(Structure.new(
                x: @cursor_pos.x, 
                y: @cursor_pos.y, 
                w: 32, 
                h: 32, 
                path: 'sprites/square/green.png',
                primitive_marker: :sprite
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
