require File.expand_path("#{File.dirname(__FILE__)}/thor_helper")

class Db < Thor
  desc "setup", "(re)create 'hyperarchy_development' database and build its schema"
  def setup
    Origin.connection = Sequel.mysql :user => 'root', :password => 'password', :host => 'localhost'
    recreate_schema("hyperarchy_development")
    recreate_schema("hyperarchy_test")
  end

  desc "load_fixtures", "load the test fixtures into the development database"
  def load_fixtures
    require "#{dir}/../spec/spec_helpers/fixtures"
    require 'logger'
    Origin.connection = Sequel.mysql('hyperarchy_development', :user => 'root', :password => 'password', :loggers => [Logger.new($stdout)])
    Monarch::Model.convert_strings_to_keys = true
    Monarch::Model::Repository::clear_tables
    Monarch::Model::Repository::load_fixtures(FIXTURES)
  end

  desc "load_examples", "load the example data into the development database"
  def load_examples
    require "#{dir}/../spec/spec_helpers/examples"
    Origin.connection = Sequel.mysql('hyperarchy_development', :user => 'root', :password => 'password')
    Monarch::Model.convert_strings_to_keys = true
    Monarch::Model::Repository::clear_tables
    Monarch::Model::Repository::load_fixtures(FIXTURES)
  end



  desc "console", "connect to the 'hyperarchy_development' database in mysql console"
  def console
    exec "/usr/bin/env mysql -uroot -ppassword hyperarchy_development"
  end

  private
  def dir
    File.dirname(__FILE__)
  end

  def recreate_schema(db_name)
    Origin.connection.execute("drop database if exists #{db_name}")
    Origin.connection.execute("create database #{db_name}")
    Origin.connection.use(db_name)
    Monarch::Model::Repository.create_schema
  end
end
