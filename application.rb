# ==========================================
# BOWER: Server
# ==========================================
# Copyright 2012 Twitter, Inc
# Licensed under The MIT License
# http://opensource.org/licenses/MIT
# ==========================================

require 'rubygems'
require 'sinatra'
require 'json'
require 'sequel'
require 'sinatra/sequel'

migration 'create packages' do
  database.create_table :packages do
    primary_key :id
    String :name, :unique => true, :null => false
    String :description, :null => false
    String :repo, :unique => true, :null => false
    Integer :hits, :default => 0
    String :author
    DateTime :created_at
    index :name
  end
end

class Package < Sequel::Model
  def hit!
    self.hits += 1
    self.save(:validate => false)
  end

  def validate
    super
    # errors.add(:url, 'is not correct format') if url !~ /^git:\/\//
  end

  def as_json
    {:name => name, :repo => repo, :description => description, :author => author}
  end

  def to_json(*)
    as_json.to_json
  end
end

get '/packages' do
  Package.order(:name).all.to_json
end

post '/packages' do
  begin
    Package.create(
      :name => params[:name],
      :repo  => params[:repo],
      :description => params[:description],
      :author => params[:author]
    )
    201
  rescue Sequel::ValidationFailed
    400
  rescue Sequel::DatabaseError
    406
  end
end

get '/packages/:name' do
  package  = Package[:name => params[:name]]

  return 404 unless package

  package.hit!
  package.to_json
end

get '/packages/search/:name' do
  packages = Package.filter(:name.ilike("%#{params[:name]}%")).order(:hits.desc)
  packages.all.to_json
end

get '/packages/:name/:version/:file' do
  package  = Package[:name => params[:name]]
  return 404 unless package
  redirect "https://raw.github.com/#{package.repo}/#{params[:version]}/#{params[:file]}"
end
