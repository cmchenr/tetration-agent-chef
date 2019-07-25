#
# Cookbook Name:: sensor
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
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
	elsif node['platform_version'] =~ /(14\.04|14\.10)/
		$sensor_flavor = 'u14'
		$enforcement = true
		$deep_visibility_agent = true
	elsif node['platform_version'] =~ /(16\.04)/
		$sensor_flavor = 'u16'
		$enforcement = true
		$deep_visibility_agent = true
	elsif node['platform_version'] =~ /(18\.04)/
		$sensor_flavor = 'u18'
		$enforcement = true
		$deep_visibility_agent = true
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
		$deep_visibility_agent = true
	elsif node['platform_version'] =~ /^6\.[0-9]+/
		$sensor_flavor = 'el6'
		$enforcement = true
		$deep_visibility_agent = true
	elsif node['platform_version'] =~ /^7\.[0-9]+/
		$sensor_flavor = 'el7'
		$enforcement = true
		$deep_visibility_agent = true
	elsif node['platform_version'] =~ /^8\.[0-9]+/
		$sensor_flavor = 'el8'
		$enforcement = true
		$deep_visibility_agent = true
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
	if ($target_sensor_type == 'enforcement') && ($enforcement == true) 
		$win_sensor_installer_file = "tetration_installer_enforcer_windows.ps1"
	elsif (($target_sensor_type == 'enforcement') || ($target_sensor_type == 'sensor')) && ($deep_visibility_agent == true) 
		$win_sensor_installer_file = "tetration_installer_sensor_windows.ps1"
	else
		raise "unable to find a supported sensor/enforcer combination for this host"
	end
	directory $win_installer_dir do
		action :create
	end
	cookbook_file $win_installer_dir + '\\' + $win_sensor_installer_file do
		source $win_sensor_installer_file
	end
	powershell_script 'Installing Sensor' do
		code '. '+ $win_installer_dir + '\\' + $win_sensor_installer_file + ' -skipEnforcementCheck'
	end
end

def linux_install_actions()
 	if ($target_sensor_type == 'enforcement') && ($enforcement == true) 
		sensor_file = "tetration_installer_enforcer_linux.sh"
	elsif (($target_sensor_type == 'enforcement') || ($target_sensor_type == 'sensor')) && ($deep_visibility_agent == true) 
		sensor_file = "tetration_installer_sensor_linux.sh"
	else 
		raise "unable to find a supported sensor/enforcer combination for this host"
	end
	package 'check unzip' do
		package_name 'unzip'
		action :upgrade
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
		mode '755'
		action :create
	end
	execute 'sensor_install' do
		command "/tmp/#{sensor_file}"
	end
end

if "#{found_os}" == "windows"
	windows_install_actions
elsif "#{found_os}" == "linux"
	linux_install_actions
end
