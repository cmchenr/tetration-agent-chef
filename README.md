# Chef HOW-TO
The following steps may be used to setup a **basic** chef environment.

## Caveats:
- SuSE 11.x doesn't [easily] support the latest version of Chef (12.16.x), which requires GLIBC 2.12+. SuSE 11.x doesn't have a pre-packaged GLIBC binary beyond 2.11.
 - Older versions of the chef-cleint for SLES are available [here](https://downloads.chef.io/chef-client/sles/), but watch out for issues when proxy servers are present.
- Multi-packages installs with [package_name](https://docs.chef.io/resource_package.html) were added in 12.1.0: https://github.com/chef/chef/issues/3786 

## Reference Documentation
	https://docs.chef.io/release/server_12-8/install_server.html#standalone
	https://docs.chef.io/install_bootstrap.html

## Download `chef-server` & `chef-manage`
#### Sources: 
- https://downloads.chef.io/
 - https://downloads.chef.io/chef-server/
 - https://downloads.chef.io/chef-manage/

Here we are using CentOS 7:

	wget https://packages.chef.io/stable/el/7/chef-server-core-12.10.0-1.el7.x86_64.rpm
	wget https://packages.chef.io/stable/el/7/chef-manage-2.4.4-1.el7.x86_64.rpm

# Install `chef-server`
	rpm -Uvh chef-server-core-12.10.0-1.el7.x86_64.rpm
	chef-server-ctl reconfigure
	
## Create chef administrative user
	chef-server-ctl user-create mafinn Matt Finn mafinn@cisco.com 'cisco123' --filename /root/mafinn.pem

## Create chef organization
	chef-server-ctl org-create tetration 'Cisco Tetration' --association_user mafinn --filename /root/tetration-validator.pem

# Install `chef-manage`
	chef-server-ctl install chef-manage --path /root/
	chef-server-ctl reconfigure
	chef-manage-ctl reconfigure --accept-license
**`NOTE:`**You can now web browse to https://chef-server-ip/ for chef server managment actions, but this document will continue the process within the CLI.
	
# Setup `knife` for `chef-client` install/bootstrap

	[root@centos-7 ~]# ln -s /opt/opscode/bin/knife /usr/local/bin/knife
	[root@centos-7 ~]# knife configure inital
	WARNING: No knife configuration file found
	Where should I put the config file? [/root/.chef/knife.rb] 
	Please enter the chef server URL: [https://centos-7.cisco.com:443] https://centos-7.cisco.com:443/organizations/tetration
	Please enter an existing username or clientname for the API: [root] mafinn
	Please enter the validation clientname: [chef-validator] tetration-validator
	Please enter the location of the validation key: [/etc/chef-server/chef-validator.pem] /root/tetration-validator.pem
	Please enter the path to a chef repository (or leave blank): 
	*****

	You must place your client key in:
	  /root/.chef/mafinn.pem
	Before running commands with Knife

	*****

	You must place your validation key in:
	  /root/tetration-validator.pem
	Before generating instance data with Knife

	*****
	Configuration file written to /root/.chef/knife.rb
	[root@centos-7 ~]# cp /root/mafinn.pem /root/.chef/
	[root@centos-7 ~]# file /root/tetration-validator.pem 
	/root/tetration-validator.pem: PEM RSA private key
	[root@centos-7 ~]# pwd
	/root
	[root@centos-7 ~]# cat .chef/knife.rb 
	log_level                :info
	log_location             STDOUT
	node_name                'mafinn'
	client_key               '/root/.chef/mafinn.pem'
	validation_client_name   'tetration-validator'
	validation_key           '/root/tetration-validator.pem'
	chef_server_url          'https://centos-7.cisco.com:443/organizations/tetration'
	syntax_check_cache_path  '/root/.chef/syntax_check_cache'
	
**`OPTIONAL:` Setup knife to support bootstrap of windows `chef-clients`:**

	[root@centos-7 ~]# ln -s /opt/opscode/embedded/bin/rake /usr/local/bin/rake
	[root@centos-7 ~]# ln -s /opt/opscode/embedded/bin/ruby /usr/local/bin/ruby
	[root@centos-7 ~]# ln -s /opt/opscode/embedded/bin/gem /usr/local/bin/gem
	[root@centos-7 ~]# yum -y install git
	<snip>
	[root@centos-7 ~]# git clone http://github.com/chef/knife-windows.git
	Cloning into 'knife-windows'...
	remote: Counting objects: 5105, done.
	remote: Compressing objects: 100% (89/89), done.
	remote: Total 5105 (delta 42), reused 0 (delta 0), pack-reused 5005
	Receiving objects: 100% (5105/5105), 992.09 KiB | 478.00 KiB/s, done.
	Resolving deltas: 100% (2527/2527), done.
	[root@centos-7 ~]# cd knife-windows/
	[root@centos-7 knife-windows]# rake build
	knife-windows 1.7.1 built to pkg/knife-windows-1.7.1.gem.
	[root@centos-7 knife-windows]# gem install pkg/knife-windows-1.7.1.gem 
	<snip>
	Done installing documentation for gssapi, rubyntlm, little-plugger, logging, nori, gyoku, winrm, rubyzip, winrm-fs, winrm-elevated, knife-windows after 4 seconds
	11 gems installed
	[root@centos-7 knife-windows]#
# Install the `chef-client` using `knife`
__`NOTE`__:SSH PKA has already been configured

## `knife` for linux `chef-clients`:

**`non-sudo` example:**

	nd=centos-5-11.cisco.com; knife bootstrap $nd -N $nd --bootstrap-proxy http://proxy-sjc-2.cisco.com:8080 --bootstrap-no-proxy centos-7.cisco.com --node-ssl-verify-mode none

**`sudo` example:**

	nd=ubuntu-server-16-04.cisco.com; knife bootstrap $nd -N $nd --bootstrap-proxy http://proxy-sjc-2.cisco.com:8080 --bootstrap-no-proxy centos-7.cisco.com --node-ssl-verify-mode none --ssh-user cisco --sudo

**Example execution:**

	[root@centos-7 ~]# knife bootstrap centos-5-11.cisco.com -N centos-5-11.cisco.com --bootstrap-proxy http://proxy-sjc-2.cisco.com:8080 --bootstrap-no-proxy centos-7.cisco.com --node-ssl-verify-mode none
	Doing old-style registration with the validation key at /root/tetration-validator.pem...
	Delete your validation key in order to use your user credentials instead

	Connecting to centos-5-11.cisco.com
	centos-5-11.cisco.com -----> Installing Chef Omnibus (-v 12)
	centos-5-11.cisco.com downloading https://omnitruck-direct.chef.io/chef/install.sh
	centos-5-11.cisco.com   to file /tmp/install.sh.3276/install.sh
	centos-5-11.cisco.com trying wget...
	centos-5-11.cisco.com el 5 x86_64
	centos-5-11.cisco.com Getting information for chef stable 12 for el...
	centos-5-11.cisco.com downloading https://omnitruck-direct.chef.io/stable/chef/metadata?v=12&p=el&pv=5&m=x86_64
	centos-5-11.cisco.com   to file /tmp/install.sh.3284/metadata.txt
	centos-5-11.cisco.com trying wget...
	centos-5-11.cisco.com sha1	8b3af710fd6308ab96b8c0625c770aebf1cf0ea8
	centos-5-11.cisco.com sha256	74e49aaa70e20a4c656e19009533988a9a44eeaa5430657551c2120718572245
	centos-5-11.cisco.com url	http://packages.chef.io/files/stable/chef/12.16.42/el/5/chef-12.16.42-1.el5.x86_64.rpm
	centos-5-11.cisco.com version	12.16.42
	centos-5-11.cisco.com downloaded metadata file looks valid...
	centos-5-11.cisco.com downloading http://packages.chef.io/files/stable/chef/12.16.42/el/5/chef-12.16.42-1.el5.x86_64.rpm
	centos-5-11.cisco.com   to file /tmp/install.sh.3284/chef-12.16.42-1.el5.x86_64.rpm
	centos-5-11.cisco.com trying wget...
	centos-5-11.cisco.com Comparing checksum with sha256sum...
	centos-5-11.cisco.com Installing chef 12
	centos-5-11.cisco.com installing with rpm...
	centos-5-11.cisco.com warning: /tmp/install.sh.3284/chef-12.16.42-1.el5.x86_64.rpm: Header V3 DSA signature: NOKEY, key ID 83ef826a
	centos-5-11.cisco.com Preparing...                ########################################### 	[100%]
	centos-5-11.cisco.com    1:chef                   ########################################### 	[100%]
	centos-5-11.cisco.com Thank you for installing Chef!
	centos-5-11.cisco.com Starting the first Chef Client run...
	centos-5-11.cisco.com Starting Chef Client, version 12.16.42
	centos-5-11.cisco.com Creating a new client identity for centos-5-11.cisco.com using the validator key.
	centos-5-11.cisco.com resolving cookbooks for run list: []
	centos-5-11.cisco.com Synchronizing Cookbooks:
	centos-5-11.cisco.com Installing Cookbook Gems:
	centos-5-11.cisco.com Compiling Cookbooks...
	centos-5-11.cisco.com [2016-11-11T13:16:02-06:00] WARN: Node centos-5-11.cisco.com has an empty run list.
	centos-5-11.cisco.com Converging 0 resources
	centos-5-11.cisco.com 
	centos-5-11.cisco.com Running handlers:
	centos-5-11.cisco.com Running handlers complete
	centos-5-11.cisco.com Chef Client finished, 0/0 resources updated in 01 seconds
	[root@centos-7 ~]# 
## `knife` for windows `chef-clients`:

**`NOTE:`** WinRM has already been configured on the target windows nodes.

**`NOTE:`** `knife-windows` must be installed to support winrm based bootstrap, see installation instructions above.

	[root@centos-7 ~]# knife bootstrap windows winrm 192.168.2.80 -x contoso\\mafinn -N rcdn-tet-win80.contoso.com --install-as-service --bootstrap-proxy http://proxy-sjc-2.cisco.com:8080 --bootstrap-no-proxy centos-7.cisco.com --node-ssl-verify-mode none
	Enter your password: 
	Doing old-style registration with the validation key at /root/tetration-validator.pem...
	Delete your validation key in order to use your user credentials instead


	Waiting for remote response before bootstrap.192.168.2.80 . 
	192.168.2.80 Response received.
	Remote node responded after 0.0 minutes.
	Bootstrapping Chef on 192.168.2.80
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 1 
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 2 
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 3 
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 4 
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 5 
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 6 
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 7 
	192.168.2.80 Rendering "C:\Users\mafinn\AppData\Local\Temp\bootstrap-32766-1480441111.bat" chunk 8 
	192.168.2.80 
	<snip>
	192.168.2.80 C:\Users\mafinn>chef-client -c c:/chef/client.rb -j c:/chef/first-boot.json 
	192.168.2.80 [2016-11-29T11:42:49-06:00] INFO: *** Chef 12.16.42 ***
	192.168.2.80 [2016-11-29T11:42:49-06:00] INFO: Platform: x64-mingw32
	192.168.2.80 [2016-11-29T11:42:49-06:00] INFO: Chef-client pid: 2512
	192.168.2.80 [2016-11-29T11:42:53-06:00] INFO: Client key C:\chef\client.pem is not present - registering
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: HTTP Request Returned 404 Object Not Found: error
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Setting the run_list to [] from CLI options
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Run List is []
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Run List expands to []
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Starting Chef Run for rcdn-tet-win80.contoso.com
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Running start handlers
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Start handlers complete.
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: HTTP Request Returned 404 Not Found: 
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: HTTP Request Returned 404 Not Found: 
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Error while reporting run start to Data Collector. URL: https://centos-7.cisco.com:443/organizations/tetration/data-collector Exception: 404 -- 404 "Not Found"  (This is normal if you do not have Chef Automate)
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Loading cookbooks []
	192.168.2.80 [2016-11-29T11:42:54-06:00] WARN: Node rcdn-tet-win80.contoso.com has an empty run list.
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Chef Run complete in 0.359345 seconds
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Running report handlers
	192.168.2.80 [2016-11-29T11:42:54-06:00] INFO: Report handlers complete
	[root@centos-7 ~]#
# List `chef-server` clients
	[root@centos-7 ~]# knife ssl fetch
	WARNING: Certificates from centos-7.cisco.com will be fetched and placed in your trusted_cert
	directory (/root/.chef/trusted_certs).

	Knife has no means to verify these are the correct certificates. You should
	verify the authenticity of these certificates after downloading.

	Adding certificate for centos-7.cisco.com in /root/.chef/trusted_certs/centos-7_cisco_com.crt
	[root@centos-7 ~]# knife node list all
	centos-5-11.cisco.com
	centos-6-8.cisco.com
	cos-7.cisco.com
	rcdn-tet-win80.contoso.com
	rhel-5-11.cisco.com
	rhel-6-8.cisco.com
	rhel-7-2.cisco.com
	suse-11-4.cisco.com
	suse-12-2.cisco.com
	ubuntu-server-12-04.cisco.com
	ubuntu-server-14-04.cisco.com
	ubuntu-server-16-04.cisco.com
	[root@centos-7 ~]# 
# Test connectivity to `chef-clients`:
## Linux:

**non-sudo:**

	[root@centos-7 ~]# knife ssh "name:rhel*" "ohai | grep -i platform_family"
	rhel-5-11.cisco.com   "platform_family": "rhel",
	rhel-7-2.cisco.com    "platform_family": "rhel",
	rhel-6-8.cisco.com    "platform_family": "rhel",
	[root@centos-7 ~]# knife ssh "name:cent*" "ohai | grep -i platform_family"
	centos-5-11.cisco.com   "platform_family": "rhel",
	centos-6-8.cisco.com    "platform_family": "rhel",
	[root@centos-7 ~]# knife ssh "name:suse*" "ohai | grep -i platform_family"
	suse-11-4.cisco.com   "platform_family": "suse",
	suse-12-2.cisco.com   "platform_family": "suse",
	
**sudo:**

	[root@centos-7 ~]# knife ssh "name:ubuntu*" "ohai | grep -i platform_family" --ssh-user cisco
	ubuntu-server-16-04.cisco.com   "platform_family": "debian",
	ubuntu-server-12-04.cisco.com   "platform_family": "debian",
	ubuntu-server-14-04.cisco.com   "platform_family": "debian",
	[root@centos-7 ~]# 

## windows:
	[root@centos-7 ~]# knife winrm "name:rcdn*" "ohai | findstr platform_family" -x contoso\\mafinn
	Enter your password: 
	rcdn-tet-win80.contoso.com   "platform_family": "windows",
	[root@centos-7 ~]# 
	
# Create a Cookbook
	[root@centos-7 ~]# knife cookbook create sensor
	WARN: This command is being deprecated in favor of `chef generate cookbook` and will soon return an error.
	Please use `chef generate cookbook` instead of this command.
	 at /opt/opscode/embedded/lib/ruby/gems/2.2.0/gems/chef-12.16.27/lib/chef/knife.rb:443:in `block in run_with_pretty_exceptions'
	** Creating cookbook sensor in /var/chef/cookbooks
	** Creating README for cookbook: sensor
	** Creating CHANGELOG for cookbook: sensor
	** Creating metadata for cookbook: sensor
	[root@centos-7 cookbooks]# find /var/chef/cookbooks/
	/var/chef/cookbooks/
	/var/chef/cookbooks/sensor
	/var/chef/cookbooks/sensor/attributes
	/var/chef/cookbooks/sensor/recipes
	/var/chef/cookbooks/sensor/recipes/default.rb
	/var/chef/cookbooks/sensor/definitions
	/var/chef/cookbooks/sensor/libraries
	/var/chef/cookbooks/sensor/resources
	/var/chef/cookbooks/sensor/providers
	/var/chef/cookbooks/sensor/files
	/var/chef/cookbooks/sensor/files/default
	/var/chef/cookbooks/sensor/templates
	/var/chef/cookbooks/sensor/templates/default
	/var/chef/cookbooks/sensor/README.md
	/var/chef/cookbooks/sensor/CHANGELOG.md
	/var/chef/cookbooks/sensor/metadata.rb
	[root@centos-7 cookbooks]# 

## Move files into the cookbook:
	[root@centos-7 ~]# cp /tmp/Ubuntu-12.04.tet-sensor-1.102.21-1.u12-ivana.x86_64.rpm /var/chef/cookbooks/sensor/files/default/tet-sensor-1.102.21-1.u12-ivana.x86_64.rpm
	[root@centos-7 ~]# cp /tmp/Ubuntu-14.04.tet-sensor-1.102.21-1.u14-ivana.x86_64.rpm /var/chef/cookbooks/sensor/files/default/tet-sensor-1.102.21-1.u14-ivana.x86_64.rpm
	[root@centos-7 ~]# cp /tmp/CentOS-5.1.tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm /var/chef/cookbooks/sensor/files/default/tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm
	[root@centos-7 ~]# cp /tmp/CentOS-6.1.tet-sensor-1.102.21-1.el6-ivana.x86_64.rpm /var/chef/cookbooks/sensor/files/default/tet-sensor-1.102.21-1.el6-ivana.x86_64.rpm
	[root@centos-7 ~]# 	

## Edit the default recipe:
Place the following [Code Source](http://gitlab.cisco.com/AS_TA/as_ta_scripting_library/blob/master/sensor_scripts/chef_cookbooks/sensor/recipes/default.rb) into `/var/chef/cookbooks/sensor/recipes/default.rb`
	
## Upload the cookbook
	[root@centos-7 ~]# knife cookbook upload sensor
	Uploading sensor       [0.1.0]
	Uploaded 1 cookbook.
	[root@centos-7 ~]# knife cookbook list all
	sensor   0.1.0
	[root@centos-7 ~]# 
	
## Assign cookbook to node run list:

Ensure the "run\_list" references the new cookbook:

`  "run_list": [
        "recipe[sensor]"
]`

	[root@centos-7 ~]# export EDITOR=vim
	[root@centos-7 ~]# knife node edit centos-5-11.cisco.com -a
	Saving updated run_list on node centos-5-11.cisco.com
	[root@centos-7 ~]# 

## Test the cookbook:
	[root@centos-7 ~]# ssh -l root centos-5-11.cisco.com 'chef-client'
	[2016-11-11T14:10:25-06:00] INFO: Forking chef instance to converge...
	[2016-11-11T14:10:25-06:00] INFO: *** Chef 12.16.42 ***
	[2016-11-11T14:10:25-06:00] INFO: Platform: x86_64-linux
	[2016-11-11T14:10:25-06:00] INFO: Chef-client pid: 3619
	[2016-11-11T14:10:26-06:00] INFO: Run List is [recipe[sensor]]
	[2016-11-11T14:10:26-06:00] INFO: Run List expands to [sensor]
	[2016-11-11T14:10:26-06:00] INFO: Starting Chef Run for centos-5-11.cisco.com
	[2016-11-11T14:10:26-06:00] INFO: Running start handlers
	[2016-11-11T14:10:26-06:00] INFO: Start handlers complete.
	[2016-11-11T14:10:26-06:00] INFO: HTTP Request Returned 404 Not Found: 
	[2016-11-11T14:10:26-06:00] INFO: HTTP Request Returned 404 Not Found: 
	[2016-11-11T14:10:26-06:00] INFO: Error while reporting run start to Data Collector. URL: https://centos-7.cisco.com:443/organizations/tetration/data-collector Exception: 404 -- 404 "Not Found"  (This is normal if you do not have Chef Automate)
	[2016-11-11T14:10:26-06:00] INFO: Loading cookbooks [sensor@0.1.0]
	[2016-11-11T14:10:26-06:00] INFO: Storing updated cookbooks/sensor/recipes/default.rb in the cache.
	[2016-11-11T14:10:26-06:00] INFO: Storing updated cookbooks/sensor/files/default/tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm in the cache.
	[2016-11-11T14:10:27-06:00] INFO: Storing updated cookbooks/sensor/files/default/tet-sensor-1.102.21-1.el6-ivana.x86_64.rpm in the cache.
	[2016-11-11T14:10:27-06:00] INFO: Storing updated cookbooks/sensor/metadata.rb in the cache.
	[2016-11-11T14:10:27-06:00] INFO: Storing updated cookbooks/sensor/README.md in the cache.
	[2016-11-11T14:10:27-06:00] INFO: Storing updated cookbooks/sensor/CHANGELOG.md in the cache.
	[2016-11-11T14:10:27-06:00] INFO: Storing updated cookbooks/sensor/files/default/tet-sensor-1.102.21-1.u12-ivana.x86_64.rpm in the cache.
	[2016-11-11T14:10:27-06:00] INFO: Storing updated cookbooks/sensor/files/default/tet-sensor-1.102.21-1.u14-ivana.x86_64.rpm in the cache.
	[2016-11-11T14:10:27-06:00] INFO: Processing execute[update_repo] action run (sensor::default line 27)
	[2016-11-11T14:11:17-06:00] INFO: execute[update_repo] ran successfully
	[2016-11-11T14:11:17-06:00] INFO: execute[update_repo] sending upgrade action to yum_package[install_deps] (immediate)
	[2016-11-11T14:11:17-06:00] INFO: Processing yum_package[install_deps] action upgrade (sensor::default line 40)
	[2016-11-11T14:11:17-06:00] INFO: yum_package[install_deps] installing redhat-lsb-4.0-2.1.4.el5 from base repository curl-7.15.5-17.el5_9 from base repository
	[2016-11-11T14:12:27-06:00] INFO: yum_package[install_deps] upgraded ["redhat-lsb", "curl"] to ["4.0-2.1.4.el5", "7.15.5-17.el5_9"]
	[2016-11-11T14:12:27-06:00] INFO: Processing yum_package[install_deps] action nothing (sensor::default line 40)
	[2016-11-11T14:12:27-06:00] INFO: Processing cookbook_file[/tmp/tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm] action create (sensor::default line 46)
	[2016-11-11T14:12:27-06:00] INFO: cookbook_file[/tmp/tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm] created file /tmp/tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm
	[2016-11-11T14:12:27-06:00] INFO: cookbook_file[/tmp/tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm] updated file contents /tmp/tet-sensor-1.102.21-1.el5-ivana.x86_64.rpm
	[2016-11-11T14:12:27-06:00] INFO: Processing rpm_package[sensor_rpm] action upgrade (sensor::default line 51)
	[2016-11-11T14:12:29-06:00] INFO: rpm_package[sensor_rpm] upgraded sensor_rpm to 1.102.21-1
	[2016-11-11T14:12:29-06:00] INFO: Chef Run complete in 123.147354 seconds
	[2016-11-11T14:12:29-06:00] INFO: Running report handlers
	[2016-11-11T14:12:29-06:00] INFO: Report handlers complete
	[root@centos-7 ~]# ssh -l root centos-5-11.cisco.com 'ps -ef | grep -i tet'
	root      5035     1  0 14:12 ?        00:00:00 tet-engine                                       
	root      5038  5035  0 14:12 ?        00:00:00 tet-engine check_conf                            
	root      5039  5035  1 14:12 ?        00:00:00 tet-sensor -f sensor.conf
	root      5073  5068  0 14:12 ?        00:00:00 bash -c ps -ef | grep -i tet
	root      5081  5073  0 14:12 ?        00:00:00 grep -i tet
	[root@centos-7 ~]# 

# Appendix:

## Manual `chef-client` installation:

### Actions on the `chef-client`:
	suse-11-4:~ # wget https://packages.chef.io/stable/sles/11.2/chef-12.0.3-1.x86_64.rpm
	--2016-11-18 12:56:21--  https://packages.chef.io/stable/sles/11.2/chef-12.0.3-1.x86_64.rpm
	Resolving proxy-sjc-2.cisco.com... 173.36.224.109, 2001:420:620::5
	Connecting to proxy-sjc-2.cisco.com|173.36.224.109|:8080... connected.
	Proxy request sent, awaiting response... 301 Moved Permanently
	Location: https://packages.chef.io/files/stable/chef/12.0.3/sles/11.2/chef-12.0.3-1.x86_64.rpm [following]
	--2016-11-18 12:56:22--  https://packages.chef.io/files/stable/chef/12.0.3/sles/11.2/chef-12.0.3-1.x86_64.rpm
	Connecting to proxy-sjc-2.cisco.com|173.36.224.109|:8080... connected.
	Proxy request sent, awaiting response... 200 OK
	Length: 41076694 (39M) [application/x-rpm]
	Saving to: `chef-12.0.3-1.x86_64.rpm'

	100%[=============================================================================================================================================>] 41,076,694   732K/s   in 56s     

	2016-11-18 12:57:17 (722 KB/s) - `chef-12.0.3-1.x86_64.rpm' saved [41076694/41076694]

	suse-11-4:~ # rpm -qa | grep -i chef
	suse-11-4:~ # rpm -Uvh chef-12.0.3-1.x86_64.rpm 
	warning: chef-12.0.3-1.x86_64.rpm: Header V3 DSA signature: NOKEY, key ID 83ef826a
	Preparing...                ########################################### [100%]
	   1:chef                   ########################################### [100%]
	Thank you for installing Chef!
	suse-11-4:~ #

### Actions on the `chef-server`:
	[root@centos-7 ~]# nd=suse-11-4.cisco.com; knife bootstrap $nd -N $nd --node-ssl-verify-mode none
	Doing old-style registration with the validation key at /root/tetration-validator.pem...
	Delete your validation key in order to use your user credentials instead

	Connecting to suse-11-4.cisco.com
	suse-11-4.cisco.com -----> Existing Chef installation detected
	suse-11-4.cisco.com Starting the first Chef Client run...
	suse-11-4.cisco.com [2016-11-18T13:17:46-06:00] WARN: 
	suse-11-4.cisco.com * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	suse-11-4.cisco.com SSL validation of HTTPS requests is disabled. HTTPS connections are still
	suse-11-4.cisco.com encrypted, but chef is not able to detect forged replies or man in the middle
	suse-11-4.cisco.com attacks.
	suse-11-4.cisco.com 
	suse-11-4.cisco.com To fix this issue add an entry like this to your configuration file:
	suse-11-4.cisco.com 
	suse-11-4.cisco.com ```
	suse-11-4.cisco.com   # Verify all HTTPS connections (recommended)
	suse-11-4.cisco.com   ssl_verify_mode :verify_peer
	suse-11-4.cisco.com 
	suse-11-4.cisco.com   # OR, Verify only connections to chef-server
	suse-11-4.cisco.com   verify_api_cert true
	suse-11-4.cisco.com ```
	suse-11-4.cisco.com 
	suse-11-4.cisco.com To check your SSL configuration, or troubleshoot errors, you can use the
	suse-11-4.cisco.com `knife ssl check` command like so:
	suse-11-4.cisco.com 
	suse-11-4.cisco.com ```
	suse-11-4.cisco.com   knife ssl check -c /etc/chef/client.rb
	suse-11-4.cisco.com ```
	suse-11-4.cisco.com 
	suse-11-4.cisco.com * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	suse-11-4.cisco.com 
	suse-11-4.cisco.com Starting Chef Client, version 12.0.3
	suse-11-4.cisco.com Creating a new client identity for suse-11-4.cisco.com using the validator key.
	suse-11-4.cisco.com resolving cookbooks for run list: []
	suse-11-4.cisco.com Synchronizing Cookbooks:
	suse-11-4.cisco.com Compiling Cookbooks...
	suse-11-4.cisco.com [2016-11-18T13:17:47-06:00] WARN: Node suse-11-4.cisco.com has an empty run list.
	suse-11-4.cisco.com Converging 0 resources
	suse-11-4.cisco.com 
	suse-11-4.cisco.com Running handlers:
	suse-11-4.cisco.com Running handlers complete
	suse-11-4.cisco.com Chef Client finished, 0/0 resources updated in 1.492403289 seconds
	[root@centos-7 ~]# 