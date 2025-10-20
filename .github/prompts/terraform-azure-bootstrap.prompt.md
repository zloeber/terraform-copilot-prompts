---
mode: 'agent'
description: 'Create azure terraform code for given requirements with interactive feedback.'
---

Create Azure Terraform code for the following requirements with step-by-step reasoning and interactive feedback:

Requirements: ${input:requirements:What infrastructure do you need? Please be as detailed as possible.}

Use the interactive_feedback tool to gather any additional necessary information from the user to refine their requirements.

Use the azure-knowledge MCP tool to ensure accuracy and best practices in Azure services.
Use the terraform-mcp-server tool to generate the Terraform code to meet the refined requirements for Azure infrastructure.
Output the final Terraform code only after confirming all requirements with the user, including any refinements made through interactive feedback.
Include a markdown file with all the requirements gathered along with any you have inferred along with the final Terraform code.
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
