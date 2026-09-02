param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [string]$OutputPath,

    [string]$ReferenceDocPath,

    [string]$PandocPath,

    [switch]$UsePandocDefaultReference,

    [switch]$PreserveReferenceHeadingSpacing
)

$ErrorActionPreference = "Stop"

function Add-DefaultHeadingSeparation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DocxPath,

        [int]$SpaceAfterTwips = 120
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $wNs = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    $zip = [System.IO.Compression.ZipFile]::Open(
        $DocxPath,
        [System.IO.Compression.ZipArchiveMode]::Update
    )

    try {
        $entry = $zip.GetEntry("word/styles.xml")
        if ($null -eq $entry) {
            throw "The generated Word file does not contain word/styles.xml."
        }

        $reader = [System.IO.StreamReader]::new($entry.Open())
        try {
            $stylesText = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }

        $styles = [System.Xml.XmlDocument]::new()
        $styles.PreserveWhitespace = $true
        $styles.LoadXml($stylesText)

        $changedCount = 0
        foreach ($styleId in @("Heading1", "Heading2", "Heading3", "Heading4")) {
            $style = $styles.SelectSingleNode(
                "/*[local-name()='styles']/*[local-name()='style' and @*[local-name()='styleId']='$styleId']"
            )
            if ($null -eq $style) {
                continue
            }

            $pPr = $style.SelectSingleNode("*[local-name()='pPr']")
            if ($null -eq $pPr) {
                $pPr = $styles.CreateElement("w", "pPr", $wNs)
                [void]$style.AppendChild($pPr)
            }

            $spacing = $pPr.SelectSingleNode("*[local-name()='spacing']")
            if ($null -eq $spacing) {
                $spacing = $styles.CreateElement("w", "spacing", $wNs)
                [void]$pPr.AppendChild($spacing)
            }

            $currentAfter = $spacing.GetAttribute("after", $wNs)
            $currentAfterValue = 0
            $hasNumericAfter = [int]::TryParse($currentAfter, [ref]$currentAfterValue)
            if (-not $hasNumericAfter -or $currentAfterValue -le 0) {
                [void]$spacing.SetAttribute("after", $wNs, [string]$SpaceAfterTwips)
                $changedCount += 1
            }
        }

        if ($changedCount -gt 0) {
            $entry.Delete()
            $newEntry = $zip.CreateEntry(
                "word/styles.xml",
                [System.IO.Compression.CompressionLevel]::Optimal
            )
            $settings = [System.Xml.XmlWriterSettings]::new()
            $settings.Encoding = [System.Text.UTF8Encoding]::new($false)
            $settings.Indent = $false
            $stream = $newEntry.Open()
            $writer = [System.Xml.XmlWriter]::Create($stream, $settings)
            try {
                $styles.Save($writer)
            }
            finally {
                $writer.Dispose()
                $stream.Dispose()
            }
        }

        return $changedCount
    }
    finally {
        $zip.Dispose()
    }
}

$resolvedInput = Resolve-Path -LiteralPath $InputPath
$inputItem = Get-Item -LiteralPath $resolvedInput.Path

$defaultOutput = $false
if (-not $OutputPath) {
    $OutputPath = [System.IO.Path]::ChangeExtension($inputItem.FullName, ".docx")
    $defaultOutput = $true
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

if ($PandocPath -and -not (Test-Path -LiteralPath $PandocPath)) {
    throw "Pandoc was not found at the specified path: $PandocPath"
}

if ($UsePandocDefaultReference -and $ReferenceDocPath) {
    throw "Use either -UsePandocDefaultReference or -ReferenceDocPath, not both."
}

if (-not $ReferenceDocPath -and -not $UsePandocDefaultReference) {
    $searchDirectory = $inputItem.Directory
    while ($searchDirectory) {
        $candidateReferenceDocs = @(
            (Join-Path $searchDirectory.FullName "templates\word-reference.docx"),
            (Join-Path $searchDirectory.FullName "_templates\word-reference.docx")
        )
        foreach ($candidateReferenceDoc in $candidateReferenceDocs) {
            if (Test-Path -LiteralPath $candidateReferenceDoc) {
                $ReferenceDocPath = $candidateReferenceDoc
                break
            }
        }
        if ($ReferenceDocPath) {
            break
        }
        $searchDirectory = $searchDirectory.Parent
    }
}

if ($ReferenceDocPath) {
    $resolvedReferenceDoc = Resolve-Path -LiteralPath $ReferenceDocPath
    $ReferenceDocPath = $resolvedReferenceDoc.Path
}

if (-not $PandocPath) {
    $pandocCommand = Get-Command pandoc -ErrorAction SilentlyContinue
    if ($pandocCommand) {
        $PandocPath = $pandocCommand.Source
    }
    else {
        $windowsLocalPandoc = Join-Path $env:LOCALAPPDATA "Pandoc\pandoc.exe"
        if (Test-Path -LiteralPath $windowsLocalPandoc) {
            $PandocPath = $windowsLocalPandoc
        }
        else {
            throw "Pandoc was not found. Install it and ensure it is on PATH, or pass -PandocPath."
        }
    }
}

$temporaryOutput = Join-Path $env:TEMP ("markdown-word-export-" + [guid]::NewGuid().ToString() + ".docx")

$pandocArgs = @(
    $inputItem.FullName,
    "--from", "gfm+attributes",
    "--to", "docx",
    "--output", $temporaryOutput
)

if ($ReferenceDocPath) {
    $pandocArgs += @("--reference-doc", $ReferenceDocPath)
}

& $PandocPath @pandocArgs

if ($LASTEXITCODE -ne 0) {
    throw "Pandoc failed with exit code $LASTEXITCODE."
}

$headingStylesAdjusted = 0
if (-not $PreserveReferenceHeadingSpacing) {
    $headingStylesAdjusted = Add-DefaultHeadingSeparation -DocxPath $temporaryOutput
}

try {
    Move-Item -LiteralPath $temporaryOutput -Destination $OutputPath -Force
}
catch {
    if ($defaultOutput) {
        $fallbackOutput = Join-Path $inputItem.DirectoryName ("{0}-{1}.docx" -f $inputItem.BaseName, (Get-Date -Format "yyyyMMdd-HHmmss"))
        Move-Item -LiteralPath $temporaryOutput -Destination $fallbackOutput -Force
        $OutputPath = $fallbackOutput
        Write-Warning "The default Word output appears to be locked, so the rendered file was saved to a timestamped fallback path."
    }
    else {
        Remove-Item -LiteralPath $temporaryOutput -Force -ErrorAction SilentlyContinue
        throw
    }
}

$outputItem = Get-Item -LiteralPath $OutputPath
[pscustomobject]@{
    Input = $inputItem.FullName
    Output = $outputItem.FullName
    ReferenceDoc = if ($UsePandocDefaultReference) { "Pandoc default Word reference" } else { $ReferenceDocPath }
    HeadingStylesAdjusted = $headingStylesAdjusted
    SizeKB = [Math]::Round($outputItem.Length / 1KB, 1)
    LastWriteTime = $outputItem.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
}
