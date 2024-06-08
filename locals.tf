locals {
  scripts_to_execute = fileset(path.module, "files/*.ps1")

#   command_to_execute = <<EOF
#     powershell.exe -ExecutionPolicy Unrestricted -Command "${data.template_file.install_devops_agent.rendered} -OrganizationUrl '${var.url}' -Pat '${var.pat}' -Pool '${var.pool}' -AgentName '${var.agent-name}'"
# EOF

}