#
# Cookbook Name:: etherpad
# Recipe:: lite
#
# Copyright 2013, computerlyrik
# Modifications by OpenWatch FPC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform_family']
  when "debian", "ubuntu"
    packages = %w{gzip git-core curl python libssl-dev pkg-config build-essential}
  when "fedora","centos","rhel"
    packages = %w{gzip git-core curl python openssl-devel}
    # && yum groupinstall "Development Tools"
end

include_recipe "postgresql::server"
include_recipe "database::postgresql"

postgresql_database 'etherpad' do
  connection(
    :host      => '127.0.0.1',
    :port      => node['postgresql']['config']['port'],
    :username  => 'postgres',
    :password  => node['postgresql']['password']['postgres']
  )
  action :create
end

packages.each do |p|
  package p
end

node.set['nodejs']['install_method'] = 'source'
include_recipe "nodejs"

user = node['etherpad-lite']['service_user']
group = 'etherpad-user'
user_home = node['etherpad-lite']['service_user_home']
project_path = "#{user_home}/etherpad-lite"

group "etherpad-user" do
  gid "500"
  action :create
end

user node['etherpad-lite']['service_user'] do
  action :create
  comment "etherpad user"
  uid 5000
  gid node['etherpad-lite']['service_user_gid']
  home node['etherpad-lite']['service_user_home']
  shell "/bin/bash"
  password "$6$C3J8Sl9V$.w5ms/.IQA.xR1YSVnivutmXFIqidXjIs/Q7xzZMWt7WxWaLRUbwRw5x46zOPRXGJTG0IYBYCzGUagA4MSIgw/"
  supports :manage_home => true
end

git project_path do
  repository node['etherpad-lite']['etherpad_git_repo_url']
  action :sync
  user user
  group group
end

template "#{project_path}/settings.json" do
  owner user
  group group
  variables({
    :title => node['etherpad-lite']['title'],
    :favicon_url => node['etherpad-lite']['favicon_url'],
    :ip_address => node['etherpad-lite']['ip_address'],
    :port_number => node['etherpad-lite']['port_number'],
    :session_key => node['etherpad-lite']['session_key'],
    :ssl_enabled => node['etherpad-lite']['ssl_enabled'],
    :ssl_key_path => node['etherpad-lite']['ssl_key_path'],
    :ssl_cert_path => node['etherpad-lite']['ssl_cert_path'],
    :db_type => node['etherpad-lite']['db_type'],
    :db_user => node['etherpad-lite']['db_user'],
    :db_host => node['etherpad-lite']['db_host'],
    :db_password => node['postgresql']['password']['postgres'],
    :db_name => node['etherpad-lite']['db_name'],
    :default_text => node['etherpad-lite']['default_text'],
    :require_session => node['etherpad-lite']['require_session'],
    :edit_only => node['etherpad-lite']['edit_only'],
    :minify => node['etherpad-lite']['minify'],
    :max_age => node['etherpad-lite']['max_age'],
    :abiword_path => node['etherpad-lite']['abiword_path'],
    :require_authentication => node['etherpad-lite']['require_authentication'],
    :require_authorization => node['etherpad-lite']['require_authorization'],
    :admin_enabled => node['etherpad-lite']['admin_enabled'],
    :admin_password => node['etherpad-lite']['admin_password'],
    :log_level => node['etherpad-lite']['log_level']
  })
end

etherpad_api_key = node['etherpad-lite']['etherpad_api_key']

if etherpad_api_key != ''
  template "#{project_path}/APIKEY.txt" do
    owner user
    group group
    variables({
      :etherpad_api_key => etherpad_api_key
    })
  end
end

node_modules = project_path + "/node_modules"


# Make Nginx log dirs
log_dir = node['etherpad-lite']['logs_dir']
access_log = log_dir + '/access.log'
error_log = log_dir + '/error.log'

include_recipe 'nginx'

# Nginx config file
template node['nginx']['dir'] + "/sites-available/default" do
    source "nginx.conf.erb"
    owner node['nginx']['user']
    group node['nginx']['group']
    variables({
      :domain => node['etherpad-lite']['domain'],
      :internal_port => node['etherpad-lite']['port_number'],
      :ssl_cert => node['etherpad-lite']['ssl_cert_path'],
      :ssl_key => node['etherpad-lite']['ssl_key_path'],
      :access_log => access_log,
      :error_log => error_log,
    })
    notifies :restart, "service[nginx]"
    action :create
end

directory log_dir do
  owner user
  group group
  recursive true
  action :create
end

# Make service log file
file access_log  do
  owner user
  group group
  action :create_if_missing # see actions section below
end

# Make service log file
file error_log  do
  owner user
  group group
  action :create_if_missing # see actions section below
end

## Install dependencies
bash "installdeps" do
  user "root"
  cwd project_path
  code <<-EOH
  ./bin/installDeps.sh >> #{error_log}
  EOH
end

# Create and set permissions for node_modules
directory node_modules do
  owner user
  group group
  mode "770"
  recursive true
  action :create
end

# Install plugins
unless node['etherpad-lite']['plugins'].empty?
  node['etherpad-lite']['plugins'].each do |plugin|
    plugin_npm_module = "ep_#{plugin}"
    npm_package plugin_npm_module do
      path project_path
      action :install_local
    end
  end
end

include_recipe "runit"

runit_service "etherpad-lite"
