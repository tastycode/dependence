module Dependence
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
end
