module Dependence
  class Error < Exception 
    attr_accessor :original_exception
    def initialize(exception = $!)
      original_exception = exception
      super
    end
  end
end
