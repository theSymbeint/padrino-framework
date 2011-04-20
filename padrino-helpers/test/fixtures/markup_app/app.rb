require 'sinatra/base'
require 'haml'

class MarkupDemo < Sinatra::Base
  register Padrino::Helpers

  configure do
    set :root, File.dirname(__FILE__)
  end

  get '/:engine/:file' do
    show(params[:engine], params[:file].to_sym)
  end

  helpers do
    # show :erb, :index
    # show :haml, :index
    def show(kind, template)
      send kind.to_sym, template.to_sym
    end
  end
end

class MarkupUser
  def errors; { :fake => "must be valid", :second => "must be present", :third  => "must be a number", :email => "must be a email"}; end
  def session_id; 45; end
  def gender; 'male'; end
  def remember_me; '1'; end
  def permission; Permission.new; end
  def telephone; Telephone.new; end
  def addresses; [Address.new('Greenfield', true), Address.new('Willowrun', false)]; end
end

class Telephone
  def number; "62634576545"; end
end

class Address
  attr_accessor :name
  def initialize(name, existing); @name, @existing = name, existing; end
  def new_record?; !@existing; end
  def id; @existing ? 25 : nil; end
end

class Permission
  def can_edit; true; end
  def can_delete; false; end
end

module Outer
  class UserAccount; end
end