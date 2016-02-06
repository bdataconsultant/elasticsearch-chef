node.default['java']['jdk_version'] = 7
include_recipe "java"

#node.override[:elasticsearch][:url] = node[:elastic][:url]
node.override[:elasticsearch][:version] = node[:elastic][:version]


elasticsearch_user 'elasticsearch' do
  username node[:elastic][:user]
  groupname node[:elastic][:group]
  shell '/bin/bash'
  comment 'Elasticsearch User'
  instance_name node[:elastic][:node_name]
  action :create
end

install_dir = Hash.new
install_dir['package'] = node[:elastic][:dir]

elasticsearch_install 'elastic_installation' do
  type :tarball
  version node[:elastic][:version]
  instance_name node[:elastic][:node_name]
#  download_url node['elasticsearch']['download_urls_v2']['tar']
  download_url node['elasticsearch']['download_urls']['tar']
#  download_checksum node['elasticsearch']['checksums']["#{node[:elasticsearch][:version]}"]['tar']
  download_checksum node.elastic.checksum
  action :install 
end

mysql_tgz = File.basename(node[:elastic][:mysql_connector_url])
mysql_base = File.basename(node[:elastic][:mysql_connector_url], "-dist.zip") 

path_mysql_tgz = "/tmp/#{mysql_tgz}"

remote_file path_mysql_tgz do
  user node[:elastic][:user]
  group node[:elastic][:group]
  source node[:elastic][:mysql_connector_url]
  mode 0755
  action :create_if_missing
end


Chef::Log.info "Downloading #{mysql_base}"
Chef::Log.info "Unzipgping #{mysql_tgz}"

bash "unpack_mysql_river" do
  user node[:elastic][:user]
  group node[:elastic][:group]
    code <<-EOF
   set -e
   cd /tmp
   unzip  #{path_mysql_tgz} 
   touch #{node[:elastic][:home_dir]}/.#{mysql_base}_downloaded
EOF
  not_if { ::File.exists?( "#{node[:elastic][:home_dir]}/.#{mysql_base}_downloaded")}
end

bash "locate_mysql_river" do
  user "root"
    code <<-EOF
   set -e
   mv /tmp/#{mysql_base} #{node[:elastic][:dir]}
   chown -R #{node[:elastic][:user]} #{node[:elastic][:dir]}/#{mysql_base}
   touch #{node[:elastic][:home_dir]}/.#{mysql_base}_moved
   chown #{node[:elastic][:user]} #{node[:elastic][:home_dir]}/.#{mysql_base}_moved
EOF
  not_if { ::File.exists?( "#{node[:elastic][:home_dir]}/.#{mysql_base}_moved")}
end


user_ulimit node[:elastic][:user] do
  filehandle_limit 65535
end
