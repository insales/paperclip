# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'test/unit'
require 'shoulda'
require 'mocha/test_unit'
require 'pry'
require 'pry-byebug'
require 'tempfile'
require 'pg'

require 'active_record'
require 'active_support'
require 'rails'

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.external_at_exit = true
  Test::Unit.at_exit do
    SimpleCov.at_exit_behavior
  end
  SimpleCov.command_name 'test:units'
  SimpleCov.start do
    load_profile "test_frameworks"

    add_group "Storage", "lib/paperclip/storage/"
    add_group "Libraries", "lib/"

    track_files "{lib}/**/*.rb"
    add_filter "lib/tasks/paperclip_tasks.rake" # TODO: вообще по-хорошема надо и его покрыть
  end
end

ROOT = File.expand_path('../', __dir__)

ENV['RAILS_ENV'] = 'test'
class TestRailsApp < Rails::Application; end
Rails.application.config.root = "#{ROOT}/tmp/rails"

$LOAD_PATH << File.join(ROOT, 'lib')
$LOAD_PATH << File.join(ROOT, 'lib/paperclip') # ??

require 'paperclip'
# require File.join(ROOT, 'lib/paperclip.rb')

require 'shoulda_macros/paperclip'


FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures")
config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.try(:raise_in_transactional_callbacks=, true)
ActiveRecord::Base.establish_connection(config['test'])

def reset_class class_name
  ActiveRecord::Base.include Paperclip
  Object.send(:remove_const, class_name) rescue nil
  klass = Object.const_set(class_name, Class.new(ActiveRecord::Base))
  klass.class_eval{ include Paperclip }
  klass
end

def reset_table(_table_name, &block)
  block ||= ->(_) { true }
  ActiveRecord::Base.connection.create_table :dummies, force: true, &block
end

def modify_table(_table_name, &block)
  ActiveRecord::Base.connection.change_table :dummies, &block
end

def rebuild_model options = {}
  ActiveRecord::Base.connection.create_table :dummies, force: true do |table|
    table.column :other, :string
    table.column :avatar_file_name, :string
    table.column :avatar_content_type, :string
    table.column :avatar_file_size, :integer
    table.column :avatar_updated_at, :datetime
  end
  rebuild_class options
end

def rebuild_class(options = {})
  ActiveRecord::Base.include Paperclip
  begin
    Object.send(:remove_const, "Dummy")
  rescue StandardError
    nil
  end

  Object.const_set("Dummy", Class.new(ActiveRecord::Base))
  Dummy.reset_column_information
  Dummy.class_eval do
    include Paperclip
    has_attached_file :avatar, options
  end
end

class FakeModel
  def self.set_callback(...); end

  include Paperclip

  attr_accessor :avatar_file_name,
                :avatar_file_size,
                :avatar_last_updated,
                :avatar_content_type,
                :id

  def errors
    @errors ||= []
  end

  def run_callbacks name, *args
  end
end

def attachment options
  Paperclip::Attachment.build_class(:avatar, options).new(FakeModel.new)
end
