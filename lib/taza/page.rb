module Taza
  # An abstraction of a web page, place the elements you care about accessing in here as well as specify the filters that apply when trying to access the element.
  # 
  # Example:
  #   require 'taza'
  #   class HomePage < Taza::Page
  #     element(:foo) {browser.element_by_xpath('some xpath')}
  #     filter :title_given, :foo 
  #   
  #     def title_given
  #       browser.title.nil?
  #     end
  #   end
  # 
  # homepage.foo will return the element specified in the block if the filter returned true
  class Page
    attr_accessor :browser, :site
    class << self
      def elements # :nodoc:
        @elements ||= {}
      end
      def filters # :nodoc:
        @filters ||= Hash.new { [] }
      end
      def url string=nil
        if string.nil?
          @url
        else
          @url = string
        end
      end
    end

    # A element on a page
    #
    # Watir Example:
    #   class HomePage < Taza::Page
    #     element(:foo) {browser.element_by_xpath('some xpath')}
    #   end
    # homepage.foo.click
    def self.element(name, &block)
      self.elements[name] = block
    end

    def self.field(name, suffix='element', &block)
      element_name = "#{name}_#{suffix}"
      self.elements[element_name] = block
      self.class_eval <<-EOS
        def #{name}
          #{element_name}.display_value
        end
      EOS
      element_name
    end

    def self.input(name, suffix='element', &block)
      element_name = self.field(name, suffix, &block)
      self.class_eval <<-EOS
        def #{name}= value
          #{element_name}.set value
        end
      EOS
      element_name
    end

    # A filter for elemenet(s) on a page
    # Example:
    #   class HomePage < Taza::Page
    #     element(:foo) {browser.element_by_xpath('some xpath')}
    #     filter :title_given, :foo 
    #     #a filter will apply to all elements if none are specified
    #     filter :some_filter
    #     #a filter will also apply to all elements if the symbol :all is given
    #     filter :another_filter, :all
    #     
    #     def some_filter
    #       true
    #     end
    #
    #     def some_filter
    #       true
    #     end
    #
    #     def title_given
    #       browser.title.nil?
    #     end
    #   end
    def self.filter(method_name, *elements)
      elements = [:all] if elements.empty?
      elements.each do |element|
        self.filters[element] = self.filters[element] << method_name
      end
    end

    def initialize
      add_element_methods
    end

    def add_element_methods # :nodoc:
      self.class.elements.each do |element_name,element_block|
        filters = self.class.filters[element_name] + self.class.filters[:all]
        add_element_method(:filters => filters, :element_name => element_name, :element_block => element_block)
      end
    end

    def add_element_method(params) # :nodoc:
      self.class.class_eval do
        define_method(params[:element_name]) do |*args|
          check_filters(params)
          self.instance_exec(*args,&params[:element_block])
        end
      end
    end
    
    def check_filters(params) # :nodoc:
      params[:filters].each do |filter_method|
        raise FilterError, "#{filter_method} returned false for #{params[:element_name]}" unless send(filter_method)
      end
    end
    
    # Go to this page. Url is computed based the page url and the url from the
    # Site & Settings.
    def goto
      @site.goto self.class.url
    end
    # Return the full url expected for the page, taking into account the Site 
    # and settings.
    def full_url
      File.join(@site.url, self.class.url)
    end
  
  end

  class FilterError < StandardError; end
    
end
