module Dependence

  Error = Class.new(Exception) do
    attr_accessor :original_exception
    def initialize(exception = $!)
      original_exception = exception
      super
    end
  end

  class Classifier
    def initialize key, dependency_provider
      @key = key
      @provider = dependency_provider
    end
    def classify
      return :proc if @provider.kind_of? Proc
      return :method_responder if @provider.respond_to? @key
      return @provider if @provider == :instance
      fail Error, "Unresolvable dependency #{@key} is not compatible class, symbol or proc"
    end
  end

  def self.included base
    @base = base
    @base.send :extend, ClassMethods
    @base.dependent_class = base
  end


  module ClassMethods
    attr_reader :_base

    def dependent_class= base
      @_base = base
    end

    def dependencies
      @dependencies ||= {}
    end

    def requires key, options = {}
      fail Error, "Dependency #{key} requires a block" unless block_given? || options[:as]
      dependencies[key] = options[:as] || -> { yield }
      store_override key
      define_dependent_method key
    end

    private 

    def define_dependent_method key
      method_name = key.to_sym
      _base.class_eval do
        define_method(method_name, Proc.new do |*args|
          _dependency!(method_name, *args)
        end)
      end
    end

    def overwritten_methods
      @overwritten_methods ||= {}
    end

    def store_override key
      if _base.instance_methods.include? key
        overwritten_methods[key] = _base.instance_method key
      end
    end

  end

  private

  def _dependency_for key
    self.class.dependencies[key]
  end

  def _proc_dependency! key, *args
    _dependency_for(key).call.send key, *args
  end

  def _method_responder_dependency! key, *args
    _dependency_for(key).send key, *args
  end

  def _instance_dependency! key, *args
    if original_method = self.class.overwritten_methods[key]
      bound = original_method.bind self
      bound.call *args
    else
      self.send key, *args
    end
  end

  def _dependency! key, *args
    classifier = Classifier.new key, _dependency_for(key)
    klass = classifier.classify
    self.send("_#{klass}_dependency!", key, *args)
  rescue ArgumentError => e
    fail Error, "Parameter mismatch for dependency #{key} given args length #{args.length}"
  end
end
