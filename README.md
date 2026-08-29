# Wazuh Detection and Active Response Configuration
## Overview
This repository contains the Wazuh configuration and custom detection components developed for ISE5901 and is designed for examining the detection and response to adversary behaviors associated with APT29. The repository includes custom active response scripts, local rule configurations, and the primary ossec.conf configuration file used to support the research environment.

The configurations and scripts in this repository were developed for research and testing purposes and are intended to support the detection, alerting, and automated response to simulated adversary activity.

## Active Response Scripts

The ```active-response/scripts/``` directory contains custom scripts used by Wazuh Active Response. These scripts are designed to execute predefined defensive actions when specific detection rules or alert conditions are triggered.

Depending on the research scenario, active response actions may include:

- Blocking or restricting a suspicious source
- Terminating or responding to a malicious process
- Collecting additional information for analysis
- Executing a predefined containment action
- Supporting automated incident response workflows

> Note: Each script should be tested in a controlled environment before deployment.

## Local Rules

The ```rules/local_rules.xml``` file contains custom Wazuh detection rules developed for the research project.

These rules are designed to identify behaviors associated with the adversary techniques examined in the research. Where applicable, rules may be mapped to the corresponding MITRE ATT&CK tactics and techniques.

The local rules may include:

- Custom rule IDs and descriptions
- Alert severity levels
- Parent or dependent rule relationships
- Field and pattern matching conditions
- MITRE ATT&CK technique mappings
- Conditions used to trigger automated active response actions
- Wazuh Configuration

The ```configuration/ossec.conf``` file contains the Wazuh configuration used in the research environment.

The configuration may include settings related to:

- Log collection
- File integrity monitoring
- Rootcheck and system inventory
- Security event analysis
- Custom rules and decoders
- Active response configuration
- Agent and manager communication

Configuration values may need to be modified to match the directory structure, hostnames, IP addresses, and environment-specific requirements of another deployment.

## Research Context

This repository supports a research project focused on the detection and response to adaptive cyber attack scenarios. The project uses adversary behaviors associated with APT29 as a reference for developing and evaluating detection capabilities.

For the purposes of the research, data exfiltration is defined as the adversary's ultimate objective. Detection and response scenarios are therefore designed to account for the possibility that adversary tactics and techniques may change dynamically throughout the attack lifecycle while the overall objective remains constant.

The custom Wazuh rules and active response scripts are intended to demonstrate how defensive controls can identify and respond to selected adversary behaviors as an attack progresses.

## Installation and Deployment

1. Back Up Existing Configuration

Before deploying any files from this repository, back up your existing Wazuh configuration and local rules.

```
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.backup
sudo cp /var/ossec/etc/rules/local_rules.xml /var/ossec/etc/rules/local_rules.xml.backup
```

2. Deploy Custom Rules

Copy the custom local rules to the appropriate Wazuh rules directory:
```
sudo cp rules/local_rules.xml /var/ossec/etc/rules/local_rules.xml
```
Review the file before replacing an existing local_rules.xml, particularly if the target environment contains previously configured custom rules.

3. Deploy Active Response Scripts

Copy the active response scripts to the appropriate Wazuh Active Response directory and ensure that the scripts have the required permissions:
```
sudo cp active-response/scripts/<script_name> /var/ossec/active-response/bin/
sudo chmod 750 /var/ossec/active-response/bin/<script_name>
```
Replace ```<script_name>``` with the name of the applicable script.

4. Update the Wazuh Configuration

Review and apply the relevant settings from:

```configuration/ossec.conf```

The configuration should be reviewed carefully before deployment. Environment-specific settings, including paths, monitored files, agent configuration, and active response parameters, may require modification.

5. Restart Wazuh

After deploying or modifying the configuration, restart the appropriate Wazuh service:

```sudo systemctl restart wazuh-manager```

If the configuration or scripts are deployed to an endpoint running a Wazuh agent, restart the applicable agent service as needed:

```
sudo systemctl restart wazuh-agent
```

Where applicable, detection rules and research scenarios are mapped to techniques documented in the MITRE ATT&CK framework.

The specific techniques represented in this repository depend on the custom rules and scenarios implemented for the research project.

## Important Notes
These configurations and scripts were developed for a specific research environment.
They may require modification before use in another environment.
Active response actions should be reviewed carefully to prevent unintended disruption.
Automated containment actions should be tested thoroughly before deployment in production.
This repository does not guarantee complete detection coverage for APT29 or any other threat actor.
Adversary techniques evolve, and detection logic should be regularly reviewed and updated.
Disclaimer

This repository is provided for academic and research purposes. The scripts and configurations are intended to support defensive security research, detection engineering, and controlled testing.

Users are responsible for reviewing, testing, and validating all configurations and scripts before deployment. The repository author is not responsible for unintended system behavior, service disruption, data loss, or other consequences resulting from the use or modification of these files.
