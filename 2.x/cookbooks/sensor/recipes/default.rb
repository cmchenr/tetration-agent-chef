#
# Cookbook Name:: sensor
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
$sensor_version = '2.0.1.34-1'
$tet_cluster = 'marla'
$target_sensor_type = 'enforcement'
if node['kernel']['machine'] != 'x86_64'
	raise "Platform must be x86_64"
end
if node['platform'] == 'ubuntu'
	found_os = 'linux'
	$lsb_pkg = "lsb-core"
	$flock_pkg = "coreutils"
	$dmidecode = "dmidecode"
	execute "update_repo" do
		command "apt-get update"
	end
	if node['platform_version'] =~ /12\.04/
		$sensor_flavor = 'u12'
		$enforcement = false
		$deep_visibility_agent = false
		$legacy_deep_visibility_agent = true
	elsif node['platform_version'] =~ /(14\.04|14\.10)/
		$sensor_flavor = 'u14'
		$enforcement = true
		$deep_visibility_agent = true
		$legacy_deep_visibility_agent = true
	else
		raise "#{node['platform']} #{node['platform_version']} not supported"
	end
elsif node['platform_family'] == 'rhel'
	found_os = 'linux'
	$lsb_pkg = "redhat-lsb"
	$flock_pkg = "util-linux"
	$dmidecode = "dmidecode"
	execute "update_repo" do
		command "yum -y update"
	end
	if node['platform_version'] =~ /^5\.[0-9]+/
		$sensor_flavor = 'el5'
		$enforcement = false
		$deep_visibility_agent = false
		$legacy_deep_visibility_agent = true
	elsif node['platform_version'] =~ /^6\.[0-9]+/
		$sensor_flavor = 'el6'
		$enforcement = true
		$deep_visibility_agent = true
		$legacy_deep_visibility_agent = true
	elsif node['platform_version'] =~ /^7\.[0-9]+/
		$sensor_flavor = 'el7'
		$enforcement = true
		$deep_visibility_agent = true
		$legacy_deep_visibility_agent = true
	else
		raise "#{node['platform']} #{node['platform_version']} not supported"
	end
elsif node['platform_family'] == 'suse'
	found_os = 'linux'
	$lsb_pkg = "lsb-release"
	$flock_pkg = "kernel-default"
	execute "update_repo" do
		command "zypper refresh"
	end
	if node['platform_version'] =~ /^11\.[2-4]$/
		$dmidecode = "pmtools"
		$sensor_flavor = 'sles11'
		$enforcement = false
		$deep_visibility_agent = false
		$legacy_deep_visibility_agent = true
	elsif node['platform_version'] =~ /^12\.[0-9]+$/
		$dmidecode = "dmidecode"
		$sensor_flavor = 'sles12'
		$enforcement = false
		$deep_visibility_agent = false
		$legacy_deep_visibility_agent = true
	else
		raise "#{node['platform']} #{node['platform_version']} not supported"
	end
elsif node['platform_family'] == 'windows'
	if node['platform_version'] =~ /^6\.[0-3]/
		found_os = 'windows'
	end
else
		raise "#{node['platform']} #{node['platform_version']} not supported"
end

def windows_install_actions()
	$win_installer_dir = 'C:\tetter'
	$win_installer_cert_dir = 'C:\tetter\cert'
	$winpcap_installer_file = 'winpcap-silence.exe'
	$win_sensor_installer_file = 'WindowsSensorInstaller.exe'
	cookbook_file "C:\\" + $winpcap_installer_file do
		source "update/" + $winpcap_installer_file
	end
	directory $win_installer_dir do
		action :create
	end
	directory $win_installer_cert_dir do
		action :create
	end
	cookbook_file $win_installer_dir + '\sensor_config' do
		source 'update/sensor_config'
	end
	cookbook_file $win_installer_dir + '\site.cfg' do
		source 'update/site.cfg'
	end
	cookbook_file $win_installer_cert_dir + '\ca.cert' do
		source 'update/ca.cert'
	end
	cookbook_file $win_installer_dir + '\\' + $win_sensor_installer_file do
		source 'update/' + $win_sensor_installer_file
	end
	windows_package 'Installing WinPcap' do
		source "C:\\" + $winpcap_installer_file
		options '/S'
	end
	windows_package 'Installing Sensor' do
		source $win_installer_dir + '\\' + $win_sensor_installer_file
		options '/S'
	end
end

def linux_install_actions()
 	if ($target_sensor_type == 'enforcement') && ($enforcement == true) 
		sensor_file = "tet-sensor-" + $sensor_version + "." + $sensor_flavor + "-" + $tet_cluster + ".enforcer.x86_64.rpm"
	elsif (($target_sensor_type == 'enforcement') || ($target_sensor_type == 'sensor')) && ($deep_visibility_agent == true) 
		sensor_file = "tet-sensor-" + $sensor_version + "." + $sensor_flavor + "-" + $tet_cluster + ".sensor.x86_64.rpm"
	elsif (($target_sensor_type == 'enforcement') || ($target_sensor_type == 'sensor') || ($target_sensor_type == 'legacy')) && ($legacy_deep_visibility_agent == true) 
		sensor_file = "tet-sensor-" + $sensor_version + "." + $sensor_flavor + "-" + $tet_cluster + ".x86_64.rpm"
	else 
		raise "unable to find a supported sensor/enforcer combination for this host"
	end
	package 'check lsb' do
		package_name $lsb_pkg
		action :upgrade
	end
	package 'check openssl' do
		package_name 'openssl'
		action :upgrade
	end
	package 'check curl' do
		package_name 'curl'
		action :upgrade
	end
	package 'check rpm' do
		package_name 'rpm'
		action :upgrade
	end
	package 'check dmidecode' do
		package_name $dmidecode
		action :upgrade
	end
	package 'check cpio' do
		package_name 'cpio'
		action :upgrade
	end
	package 'check sed' do
		package_name 'sed'
		action :upgrade
	end
	package 'check gawk' do
		package_name 'gawk'
		action :upgrade
	end
	package 'check flock' do
		package_name $flock_pkg
		action :upgrade
	end
	cookbook_file "/tmp/#{sensor_file}" do
		source "#{sensor_file}"
		action :create
	end
	rpm_package 'sensor_rpm' do
		source "/tmp/#{sensor_file}"
		options "--nodeps"
		action :upgrade
	end
end

if "#{found_os}" == "windows"
	windows_install_actions
elsif "#{found_os}" == "linux"
	linux_install_actions
end
