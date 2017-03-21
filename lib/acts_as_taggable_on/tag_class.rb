module ActsAsTaggableOn
  class TagClass
    def initialize(class_name, base_class)
      @class_name, @base_class = "#{class_name}Tag", base_class
    end

    def class
      if @base_class.const_defined? @class_name
        @base_class.const_get @class_name
      else
        @base_class.const_set @class_name, Class.new(@base_class)
      end
    end
  end
end
