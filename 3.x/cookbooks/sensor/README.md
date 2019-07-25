# sensor Cookbook

This is a sample cookbook to install the Cisco Tetration agent on supported server platforms.

## Requirements

Agent pre-requisites can be found in your Tetration site documentation at https://%your_tetration_url%/documentation/ui/software_agents/deployment.html

The cookbook must be run with root privilages on Linux systems and Administrator privilages on Windows.

### Platforms

Supported operating systems can be found in your Tetration site documentation at https://%your_tetration_url%/documentation/ui/software_agents/deployment.html

### Chef

- Chef 12.0 or later

### Cookbooks

- `sensor` - Detects the OS type and executes the deployment-specific installer script.

## Usage

### sensor::default

Tetration installers are specific to each customer deployment.  Prior to adding the cookbook to the run list, the installer files must be placed in the "files" subfolder of the cookbook repo.  The following 4 files are required:

- tetration_installer_enforcer_linux.sh
- tetration_installer_enforcer_windows.ps1
- tetration_installer_sensor_linux.sh
- tetration_installer_sensor_windows.ps1

Instructions on obtaining these files for a specific Tetration deployment can be found in your Tetration site documentation at https://%your_tetration_url%/documentation/ui/software_agents/deployment.html

Just include `sensor` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[sensor]"
  ]
}
```

## Caveats

This cookbook applies to x86/x64 Linux and Windows deployments only.  As of this writing, Tetration also supports AIX 7.1 and 7.2 and SLES on zSystems, but they are not supported by this cookbook.

## Contributing

TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

## License and Authors

Authors: TODO: List authors

