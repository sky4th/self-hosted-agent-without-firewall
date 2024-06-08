##################################################################################
# $DEVOPSURL :- https://dev.azure.com/{organization name}/
# $DEVOPSPAT :- Personal access token to authenticate VM with azure devops
# $DEVOPSPOOL:- Name of the Azure DevOps Agent Pool where you want to register your agent 
# $DEVOPSAGENT:- Name of the agent
# AGENTVERSION:- Agent version, by default its latest version
###################################################################################
param (
    [string]$DEVOPSURL,
    [string]$DEVOPSPAT,
    [string]$DEVOPSPOOL,
    [Parameter(Mandatory=$false)][string]$DEVOPSAGENT,
    [Parameter(Mandatory=$false)]$AGENTVERSION
)

Start-Transcript

# remove an existing installation of agent
if (test-path "c:\agent")
{
    Remove-Item -Path "c:\agent" -Force  -Confirm:$false -Recurse 
}

#create a new folder
new-item -ItemType Directory -Force -Path "c:\agent"
set-location "c:\agent"

$env:VSTS_AGENT_HTTPTRACE = $true

#github requires tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#get the latest build agent version
if ($AGENTVERSION)
{
    $agent_ver = $AGENTVERSION
    write-host "installing  agent  version $AGENTVERSION"
}
else 
{
    $rsp = Invoke-WebRequest https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest -UseBasicParsing
    if ($rsp.StatusCode -eq 200)
    {
        $agent_ver = ($rsp | ConvertFrom-Json)[0].tag_name.Substring(1)
        write-host "installing  latest version $agent_ver"
    }
    else
    {
        write-host "$rsp.StatusCode"
    }
}

if ($DEVOPSAGENT)
{
    $AGENT_NAME = $DEVOPSAGENT
}
else
{
    $AGENT_NAME = $env:COMPUTERNAME
}
# URL to download the agent
$download = "https://vstsagentpackage.azureedge.net/agent/$agent_ver/vsts-agent-win-x64-$agent_ver.zip"

# Download the Agent
Invoke-WebRequest $download -Out agent.zip

# Extract the zio to agent folder
Expand-Archive -Path agent.zip -DestinationPath $PWD

# Run the cmd silently to install agent
.\config.cmd --unattended --url "$DEVOPSURL" --auth pat --token "$DEVOPSPAT" --pool "$DEVOPSPOOL" --agent $AGENT_NAME --acceptTeeEula --runAsService

#exit
Stop-Transcript
exit 0