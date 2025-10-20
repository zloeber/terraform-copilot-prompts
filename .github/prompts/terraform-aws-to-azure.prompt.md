---
mode: 'agent'
description: 'Convert AWS terraform into Azure terraform.'
---

Convert AWS terraform code into Azure terraform code in the following source directory if it exists.

Source: ${input:source:./output/aws}

Use the interactive_feedback tool to gather any additional necessary information from the user if required.

Use the azure-knowledge MCP tool to ensure accuracy and best practices in Azure services.
Use the terraform-mcp-server tool to generate the new Terraform code to meet the requirements for Azure infrastructure.
Include a markdown file with a report of the AWS versus Azure code differences including tables of resources deployed in one provider versus the other.
Refine all infrastructure requirements to be Azure-specific and aligned with best practices, security, and compliance standards. Be thorough and detailed in your analysis.
If you need to gather more information from the user to refine the requirements, use the interactive_feedback tool to ask clarifying questions before generating the code.

Rules:
    - Terraform should be written using HCL (HashiCorp Configuration Language) syntax.
    - Use the latest Azure provider version compatible with the required resources.
    - Follow best practices for Terraform code structure, including the use of variables, outputs, and modules.
    - Ensure that the generated code is well-documented with comments explaining the purpose of each resource and configuration.
    - Always try to use implicit dependencies over explicit dependencies where possible in Terraform.
    - When generating Terraform resource names, ensure they are unique and descriptive, lower-case, and snake_case.
    - Be sure to include any necessary provider configurations, backend settings, and required variables in the generated code.
    - Ensure the generated terraform code always includes a top level `tag` variable map that is used on all taggable resources, with at least the following tags: `Environment`, `Project`, and `Owner`.
    - Ensure that sensitive information such as passwords, API keys, and secrets are not hardcoded in the Terraform code. Use variables and secret management solutions instead.
    - Do not assume any prior knowledge about the user's Azure environment; always seek clarification when in doubt.
    - Do not ask for Azure specific information like instance types, instead focus on high level requirements and attempt to map them to Azure services for the user.
    - Before finalizing the Terraform code, always confirm with the user that all requirements have been accurately captured and addressed.
    - All output should be created in the `output/azure/` directory with appropriate filenames.
