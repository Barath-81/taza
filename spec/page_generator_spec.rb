require 'spec/spec_helper'
require 'rubygems'
require 'fileutils'
require 'taza'

describe "Page Generation" do
  include RubiGen::GeneratorTestHelper
  include Helpers::Generator
  include Helpers::Taza

  before :all do
    @page_name = "CheckOut"
  end

  before :each do
    run_generator('taza', [APP_ROOT], generator_sources)
    @site_class = generate_site('Gap')
  end

  after :each do
    bare_teardown
    PageGenerator.class_eval "@@default_site = nil"     
  end
  
  # Negative
  
  it "should give you usage if you give no arguments" do
    PageGenerator.any_instance.expects(:usage)
    lambda { run_generator('page', [], generator_sources) }.should raise_error(Mocha::ExpectationError)
  end
 
  it "should give you usage if you only give one argument and no default site is specified" do
    PageGenerator.any_instance.expects(:usage)
    lambda { run_generator('page', [@page_name], generator_sources) }.should raise_error(NoMethodError)
  end

  it "should give you usage if you three arguments" do
    PageGenerator.any_instance.expects(:usage)
    lambda { run_generator('page', [@page_name, @site_class.to_s, 'extra'], generator_sources) }.should raise_error(Mocha::ExpectationError)
  end

  it "should give you usage if you give a site that does not exist" do
    PageGenerator.any_instance.expects(:usage)
    $stderr.expects(:puts).with(regexp_matches(/NoSuchSite/))
    lambda { run_generator('page', [@page_name, "NoSuchSite"], generator_sources) }.should raise_error(Errno::ENOENT)
  end

  # Positive

  it "should generate a page spec that can be required" do
    run_generator('page', [@page_name,@site_class.to_s], generator_sources)
    page_functional_spec = File.join(PROJECT_FOLDER,'spec','functional',@site_class.to_s.underscore,'check_out_page_spec.rb')
    system("ruby -c #{page_functional_spec} > #{null_device}").should be_true
  end

  it "should be able to access the generated page from the site" do
    run_generator('page', [@page_name,@site_class.to_s], generator_sources)
    stub_settings
    stub_browser
    @site_class.new.check_out_page
  end

  it "should be able to access the generated page for its site" do
    stub_browser
    stub_settings
    new_site_class = generate_site('Pag')
    run_generator('page', [@page_name,@site_class.to_s], generator_sources)
    run_generator('page', [@page_name,new_site_class.to_s], generator_sources)
    new_site_class.new.check_out_page.class.should_not eql(@site_class.new.check_out_page.class)
  end

  it "should be able to generate a page when there is a site default" do
    PageGenerator.class_eval "@@default_site = '#{@site_class.to_s}'"
    lambda{run_generator('page', [@page_name], generator_sources)}.should_not raise_error
  end
    
end
