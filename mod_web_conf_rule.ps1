param (
    [Parameter(Mandatory = $true)]
    [string]$WebConfigPath
)

$ErrorActionPreference = 'Stop'

$ruleName = 'Block cookieconsent.bundle.js if Referer is Timetable/Public'

try {
    # Resolve and validate the file path
    $WebConfigPath = (Resolve-Path -LiteralPath $WebConfigPath).Path

    if ([System.IO.Path]::GetFileName($WebConfigPath) -ne 'web.config') {
        Write-Warning "The selected file is not named 'web.config': $WebConfigPath"
    }

    # Create a timestamped backup
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = "$WebConfigPath.$timestamp.bak"

    Copy-Item -LiteralPath $WebConfigPath `
              -Destination $backupPath `
              -Force

    Write-Host "Backup created: $backupPath" -ForegroundColor Green

    # Load web.config as XML
    $xml = [System.Xml.XmlDocument]::new()
    $xml.PreserveWhitespace = $true
    $xml.Load($WebConfigPath)

    # Locate system.webServer
    $systemWebServer = $xml.SelectSingleNode('/configuration/system.webServer')

    if ($null -eq $systemWebServer) {
        throw "The <system.webServer> section was not found in $WebConfigPath."
    }

    # Locate or create <rewrite>
    $rewriteNode = $systemWebServer.SelectSingleNode('rewrite')

    if ($null -eq $rewriteNode) {
        $rewriteNode = $xml.CreateElement('rewrite')
        $securityNode = $systemWebServer.SelectSingleNode('security')

        if ($null -ne $securityNode) {
            # Insert <rewrite> immediately after </security>
            [void]$systemWebServer.InsertAfter($rewriteNode, $securityNode)
        }
        else {
            [void]$systemWebServer.AppendChild($rewriteNode)
        }

        Write-Host 'Created the <rewrite> section.' -ForegroundColor Yellow
    }

    # Locate or create <rules>
    $rulesNode = $rewriteNode.SelectSingleNode('rules')

    if ($null -eq $rulesNode) {
        $rulesNode = $xml.CreateElement('rules')
        [void]$rewriteNode.AppendChild($rulesNode)

        Write-Host 'Created the <rules> section.' -ForegroundColor Yellow
    }

    # Check whether the rule already exists
    $existingRule = $rulesNode.SelectSingleNode(
        "rule[@name=""$ruleName""]"
    )

    if ($null -ne $existingRule) {
        Write-Host "Rule already exists. No changes were made: $ruleName" `
            -ForegroundColor Yellow
        exit 0
    }

    # Create <rule>
    $ruleNode = $xml.CreateElement('rule')
    $ruleNode.SetAttribute('name', $ruleName)
    $ruleNode.SetAttribute('stopProcessing', 'true')

    # Create <match>
    $matchNode = $xml.CreateElement('match')
    $matchNode.SetAttribute(
        'url',
        '.*cookieconsent\.bundle\.js'
    )
    [void]$ruleNode.AppendChild($matchNode)

    # Create <conditions>
    $conditionsNode = $xml.CreateElement('conditions')

    $conditionNode = $xml.CreateElement('add')
    $conditionNode.SetAttribute('input', '{HTTP_REFERER}')
    $conditionNode.SetAttribute('pattern', '/Timetable/Public')

    [void]$conditionsNode.AppendChild($conditionNode)
    [void]$ruleNode.AppendChild($conditionsNode)

    # Create <action>
    $actionNode = $xml.CreateElement('action')
    $actionNode.SetAttribute('type', 'CustomResponse')
    $actionNode.SetAttribute('statusCode', '403')
    $actionNode.SetAttribute('statusReason', 'Forbidden')
    $actionNode.SetAttribute(
        'statusDescription',
        'Blocked by Referer Rule'
    )

    [void]$ruleNode.AppendChild($actionNode)

    # Insert the new rule as the first rule
    if ($rulesNode.HasChildNodes) {
        [void]$rulesNode.InsertBefore(
            $ruleNode,
            $rulesNode.FirstChild
        )
    }
    else {
        [void]$rulesNode.AppendChild($ruleNode)
    }

    # Save using UTF-8 without BOM
    $writerSettings = [System.Xml.XmlWriterSettings]::new()
    $writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false)
    $writerSettings.Indent = $true
    $writerSettings.IndentChars = "`t"
    $writerSettings.NewLineChars = :NewLine
    $writerSettings.NewLineHandling =
        [System.Xml.NewLineHandling]::Replace

    $writer = [System.Xml.XmlWriter]::Create(
        $WebConfigPath,
        $writerSettings
    )

    try {
        $xml.Save($writer)
    }
    finally {
        $writer.Dispose()
    }

    Write-Host 'The URL Rewrite rule was added successfully.' `
        -ForegroundColor Green
    Write-Host "Updated file: $WebConfigPath"
}
catch {
    Write-Error "Failed to update web.config: $($_.Exception.Message)"
    exit 1
}
