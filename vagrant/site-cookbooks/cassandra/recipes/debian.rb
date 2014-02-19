#
# Cookbook Name:: cassandra
# Recipe:: datastax
#
# Copyright 2011-2012, Michael S Klishin & Travis CI Development Team
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

# This recipe relies on a PPA package and is Ubuntu/Debian specific. Please
# keep this in mind.

include_recipe "java"

user node.cassandra.user do
  comment "Cassandra Server user"
  home    node.cassandra.installation_dir
  shell   "/bin/bash"
  action  :create
end

group node.cassandra.user do
  (m = []) << node.cassandra.user
  members m
  action :create
end

[node.cassandra.data_root_dir, node.cassandra.log_dir, node.cassandra.commitlog_dir].each do |dir|
  directory dir do
    owner     node.cassandra.user
    group     node.cassandra.user
    recursive true
    action    :create
  end
end

  
    apt_repository "cassandra" do
      uri          "http://www.apache.org/dist/cassandra/debain"
      distribution "20x"
      components   ["main"]
      key           "F758CE318D77295D"
      key           "2B5C1B00"
      keyserver    "pgp.mit.edu"
  
      action :add
    end

package "cassandra" do
  action :install
end

# Define service above so chef doesn't complain
# that there is no service to send notifications to
service "cassandra"

%w(cassandra.yaml cassandra-env.sh).each do |f|
  template File.join(node["cassandra"]["conf_dir"], f) do
    cookbook node["cassandra"]["templates_cookbook"]
    source "#{f}.erb"
    owner node["cassandra"]["user"]
    group node["cassandra"]["user"]
    mode  0644
    notifies :restart, resources(:service => "cassandra")
  end
end

service "cassandra" do
  supports :restart => true, :status => true
  action [:enable, :start]
end
