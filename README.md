# Din Familiejurist Salesforce Project

This repository holds all Salesforce metadata managed through DevOps Center.

## Repository Structure
- **Main branch**: mirrors production
- **Feature branches**: created by DevOps Center per Work Item
- Use Salesforce CLI to retrieve or deploy metadata

## Development Workflow
1. Work Items are created in Salesforce DevOps Center
2. DevOps Center automatically creates feature branches
3. Metadata changes are pulled and committed through DevOps Center
4. Completed Work Items are merged to main and deployed to production

## Getting Started
To work with this repository locally:
1. Ensure you have Salesforce CLI installed
2. Authorize your org: `sfdx auth:web:login -a <alias>`
3. Retrieve metadata: `sfdx force:source:retrieve -u <alias> -p force-app`

## Resources
- [Salesforce DevOps Center Documentation](https://developer.salesforce.com/docs/atlas.en-us.devops_center.meta/devops_center/)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
