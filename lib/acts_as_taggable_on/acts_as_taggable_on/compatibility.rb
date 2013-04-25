module ActsAsTaggableOn::Compatibility
  def has_many_with_compatibility(name, options = {}, &extention)
    if ActiveRecord::VERSION::MAJOR >= 4
      scope, opts = build_scope_and_options(options)
      has_many(name, scope, opts, &extention)
    else
      has_many(name, options, &extention)
    end
  end

  def build_scope_and_options(opts)
    scope_opts, opts = parse_options(opts)

    unless scope_opts.empty?
      scope = lambda do 
        scope_opts.inject(self) { |result, hash| result.send *hash }
      end
    end

    [defined?(scope) ? scope : nil, opts]
  end

  def parse_options(opts)
    scope_opts = {}
    [:order, :having, :select, :group, :limit, :offset, :readonly].each do |o|
      scope_opts[o] = opts.delete o if opts[o]
    end
    scope_opts[:where] = opts.delete :conditions if opts[:conditions]
    scope_opts[:joins] = opts.delete :include if opts [:include]
    scope_opts[:distinct] = opts.delete :uniq if opts[:uniq]

    [scope_opts, opts]
  end
end