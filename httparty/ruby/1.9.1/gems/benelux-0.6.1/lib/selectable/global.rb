# 
# module Selectable
#   
#   class Global
#     attr_reader :names
#     def initialize(*names)
#       @names = []
#       add_groups names
#     end
#     class << self
#       def group_class
#         @group_class || Group
#       end
#       attr_writer :group_class
#     end
#     def group(name)
#       self.send name
#     end
#     # Each group
#     def each(&blk)
#       @names.each { |name| blk.call(group(name)) }
#     end
#     # Each group name, group
#     def each_pair(&blk)
#       @names.each { |name| blk.call(name, group(name)) }
#     end
#     def add_groups(*args)
#       args.flatten.each do |meth|
#         next if has_group? meth
#         @names << meth
#         self.class.send :attr_reader, meth
#         (g = Group.new).name = meth
#         instance_variable_set("@#{meth}", g)
#       end
#     end
#     alias_method :add_group, :add_groups
#     def has_group?(name)
#       @names.member? name
#     end
#     def +(other)
#       if !other.is_a?(Benelux::Stats)
#         raise TypeError, "can't convert #{other.class} into Stats" 
#       end
#       other.names.each do |name|
#         add_group name
#         a = self.send(name) 
#         a += other.send(name)
#         a
#       end
#       self
#     end
#     
#     
#     class Group < Array
#       include Selectable
#       attr_accessor :name
#       def self.extend(klass)
#         p 111111111111111
#       end
#     end
#     
#   end
# end