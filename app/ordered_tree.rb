class Ordered_Tree 
    attr_reader :branches, :resources, :named_lookup


    def initialize(branches: {})
        @branches = []
        @index = {}
    end


    def [](uid)
        return @index[uid]
    end


    def []=(uid, value)
        return @index[uid] = value
    end


    def <<(branch)
        if(@branches[branch.z] && @branches[branch.z][branch.uid])
            delete(branch)
        end

        insert(branch)
    end


    def insert(branch)
        throw "BRANCH_OUT_OF_BOUNDS::#{branch.z}" if(branch.z < 0)

        if((branch.z + 1) > @branches.length)
            add_branch(branch.z + 1)
        end
       
        @branches[branch.z][branch.uid] = branch 
        @index[branch.uid] = branch
    end


    def <<(branch)
        insert(branch)
    end


    def delete(branch)
        return nil if(!@branches[branch.z] || !@branches[branch.z][branch.uid])

        @branches[branch.z].delete(branch.uid)
        @index.delete(branch.uid)

        return branch 
    end


    def printy()
        puts "------------\n"

        @branches.each do |branch|
            puts "->#{branch}\n"
        end
    end


    def values()
        return @branches 
    end


    def empty?()
        return @branches.empty?()
    end


    def add_branch(desired_branch)
        branch_diff = desired_branch - @branches.length

        puts "branch diff #{branch_diff}"

        if(branch_diff > 0)
            branch_diff.times() do |x|
                @branches << {} 
            end
        end

        puts "branches #{@branches}"
    end
end
