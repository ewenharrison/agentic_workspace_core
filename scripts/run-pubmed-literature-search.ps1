param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [Parameter(Mandatory = $true)]
    [string]$ProtocolPath,

    [Parameter(Mandatory = $false)]
    [int]$MaxResults = 50,

    [Parameter(Mandatory = $false)]
    [ValidateSet("relevance", "pub date", "most recent")]
    [string]$Sort = "relevance",

    [Parameter(Mandatory = $false)]
    [string]$RunMode = "manual"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToSlug {
    param([Parameter(Mandatory = $true)][string]$Value)

    $slug = $Value.ToLowerInvariant()
    $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-")
    $slug = $slug.Trim("-")
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "pubmed-search"
    }
    if ($slug.Length -gt 70) {
        return $slug.Substring(0, 70).Trim("-")
    }
    return $slug
}

function Add-LineIfMissing {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Line
    )

    $content = Get-Content -LiteralPath $Path -Raw
    if ($content -notmatch [regex]::Escape($Line)) {
        $trimmed = $content.TrimEnd("`r", "`n")
        Set-Content -LiteralPath $Path -Value ($trimmed + "`r`n" + $Line + "`r`n")
    }
}

function Get-RepoRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $root = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd("\", "/")
    $full = if (Test-Path -LiteralPath $Path) {
        (Resolve-Path -LiteralPath $Path).Path
    } else {
        [System.IO.Path]::GetFullPath($Path)
    }
    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return ($full.Substring($root.Length).TrimStart("\", "/") -replace "\\", "/")
    }
    return $full
}

function Get-MarkdownSection {
    param(
        [Parameter(Mandatory = $true)][string]$Markdown,
        [Parameter(Mandatory = $true)][string]$Heading
    )

    $pattern = "(?ms)^##\s+$([regex]::Escape($Heading))\s*\r?\n(?<body>.*?)(?=^##\s+|\z)"
    $match = [regex]::Match($Markdown, $pattern)
    if ($match.Success) {
        return $match.Groups["body"].Value.Trim()
    }
    return ""
}

function Get-ProtocolValue {
    param(
        [Parameter(Mandatory = $true)][string]$Markdown,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $escaped = [regex]::Escape($Name)
    $patterns = @(
        "(?im)^\s*-\s*$escaped\s*:\s*(?<value>.+?)\s*$",
        "(?im)^\s*$escaped\s*:\s*(?<value>.+?)\s*$"
    )
    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Markdown, $pattern)
        if ($match.Success) {
            return $match.Groups["value"].Value.Trim()
        }
    }
    return ""
}

function Get-PubMedQuery {
    param([Parameter(Mandatory = $true)][string]$Markdown)

    $section = Get-MarkdownSection -Markdown $Markdown -Heading "PubMed Query"
    if (-not [string]::IsNullOrWhiteSpace($section)) {
        $fenced = [regex]::Match($section, '(?ms)```(?:text|txt|pubmed)?\s*(?<query>.*?)```')
        if ($fenced.Success) {
            return $fenced.Groups["query"].Value.Trim()
        }
        return $section.Trim()
    }

    foreach ($fieldName in @("PubMed query", "Query", "Exact query")) {
        $value = Get-ProtocolValue -Markdown $Markdown -Name $fieldName
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    throw "No PubMed query found. Add a '## PubMed Query' section with the exact query in a fenced text block."
}

function Invoke-NcbiRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $false)][int]$MaxAttempts = 3
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return Invoke-RestMethod -Uri $Uri -Method Get -Headers @{ "User-Agent" = "agentic-workspace-pubmed-search/1.0" }
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                throw
            }
            Start-Sleep -Seconds ([Math]::Min(10, 2 * $attempt))
        }
    }
}

function Convert-XmlText {
    param([object]$Node)

    if ($null -eq $Node) {
        return ""
    }
    if ($Node -is [array]) {
        return (($Node | ForEach-Object { Convert-XmlText -Node $_ }) -join " ").Trim()
    }
    if ($Node.PSObject.Properties.Name -contains "InnerText") {
        return ([string]$Node.InnerText).Trim()
    }
    return ([string]$Node).Trim()
}

function Select-XmlNodeByPath {
    param(
        [Parameter(Mandatory = $false)][object]$Node,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    if ($null -eq $Node) {
        return $null
    }

    $current = $Node
    foreach ($name in $Names) {
        if ($null -eq $current -or -not ($current -is [System.Xml.XmlNode])) {
            return $null
        }
        $current = $current.SelectSingleNode("*[local-name()='$name']")
    }
    return $current
}

function Select-XmlNodesByPath {
    param(
        [Parameter(Mandatory = $false)][object]$Node,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    if ($Names.Count -eq 0) {
        return @()
    }
    $parent = Select-XmlNodeByPath -Node $Node -Names $Names[0..($Names.Count - 2)]
    if ($null -eq $parent -or -not ($parent -is [System.Xml.XmlNode])) {
        return @()
    }
    $leafName = $Names[-1]
    return @($parent.SelectNodes("*[local-name()='$leafName']"))
}

function Get-ArticleId {
    param(
        [Parameter(Mandatory = $true)][object]$Article,
        [Parameter(Mandatory = $true)][string]$IdType
    )

    $ids = Select-XmlNodesByPath -Node $Article -Names @("PubmedData", "ArticleIdList", "ArticleId")
    foreach ($id in $ids) {
        if ($id.GetAttribute("IdType") -eq $IdType) {
            return (Convert-XmlText -Node $id)
        }
    }
    return ""
}

function Get-PubDate {
    param([object]$JournalIssue)

    $pubDate = Select-XmlNodeByPath -Node $JournalIssue -Names @("PubDate")
    if ($null -eq $pubDate) {
        return ""
    }
    $year = Convert-XmlText -Node (Select-XmlNodeByPath -Node $pubDate -Names @("Year"))
    if ($year) {
        $parts = @(
            $year,
            (Convert-XmlText -Node (Select-XmlNodeByPath -Node $pubDate -Names @("Month"))),
            (Convert-XmlText -Node (Select-XmlNodeByPath -Node $pubDate -Names @("Day")))
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
        return ($parts -join " ")
    }
    $medlineDate = Convert-XmlText -Node (Select-XmlNodeByPath -Node $pubDate -Names @("MedlineDate"))
    if ($medlineDate) {
        return $medlineDate
    }
    return ""
}

function Get-Authors {
    param([Parameter(Mandatory = $true)][object]$Article)

    $authors = Select-XmlNodesByPath -Node $Article -Names @("MedlineCitation", "Article", "AuthorList", "Author")

    $authorNames = foreach ($author in $authors) {
        $collectiveName = Convert-XmlText -Node (Select-XmlNodeByPath -Node $author -Names @("CollectiveName"))
        $lastName = Convert-XmlText -Node (Select-XmlNodeByPath -Node $author -Names @("LastName"))
        if ($collectiveName) {
            $collectiveName
        }
        elseif ($lastName) {
            $initialsValue = Convert-XmlText -Node (Select-XmlNodeByPath -Node $author -Names @("Initials"))
            $initials = if ($initialsValue) { " $initialsValue" } else { "" }
            "$lastName$initials"
        }
    }

    return (($authorNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "; ")
}

function Get-KeywordList {
    param([object]$Values)

    if ($null -eq $Values) {
        return ""
    }
    return ((@($Values) | ForEach-Object { Convert-XmlText -Node $_ } | Where-Object { $_ }) -join "; ")
}

function Convert-PubMedArticle {
    param([Parameter(Mandatory = $true)][object]$Article)

    $medline = Select-XmlNodeByPath -Node $Article -Names @("MedlineCitation")
    $articleNode = Select-XmlNodeByPath -Node $medline -Names @("Article")
    $pmid = Convert-XmlText -Node (Select-XmlNodeByPath -Node $medline -Names @("PMID"))
    $doi = Get-ArticleId -Article $Article -IdType "doi"
    $pmcid = Get-ArticleId -Article $Article -IdType "pmc"
    $pubTypes = Get-KeywordList -Values (Select-XmlNodesByPath -Node $articleNode -Names @("PublicationTypeList", "PublicationType"))
    $meshHeadings = Select-XmlNodesByPath -Node $medline -Names @("MeshHeadingList", "MeshHeading")
    $mesh = Get-KeywordList -Values ($meshHeadings | ForEach-Object { Select-XmlNodeByPath -Node $_ -Names @("DescriptorName") })
    $abstract = Convert-XmlText -Node (Select-XmlNodesByPath -Node $articleNode -Names @("Abstract", "AbstractText"))
    $journal = Select-XmlNodeByPath -Node $articleNode -Names @("Journal")

    return [pscustomobject]@{
        PMID = $pmid
        Title = Convert-XmlText -Node (Select-XmlNodeByPath -Node $articleNode -Names @("ArticleTitle"))
        Authors = Get-Authors -Article $Article
        Journal = Convert-XmlText -Node (Select-XmlNodeByPath -Node $journal -Names @("Title"))
        JournalAbbrev = Convert-XmlText -Node (Select-XmlNodeByPath -Node $journal -Names @("ISOAbbreviation"))
        PubDate = Get-PubDate -JournalIssue (Select-XmlNodeByPath -Node $journal -Names @("JournalIssue"))
        DOI = $doi
        PMCID = $pmcid
        PublicationTypes = $pubTypes
        Mesh = $mesh
        Abstract = $abstract
        PubMedUrl = "https://pubmed.ncbi.nlm.nih.gov/$pmid/"
    }
}

function Format-Value {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "Not available"
    }
    return $Value.Trim()
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "workspace\projects\$Project"
if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project '$Project' not found at '$projectRoot'."
}

$resolvedProtocolPath = if ([System.IO.Path]::IsPathRooted($ProtocolPath)) {
    $ProtocolPath
} else {
    Join-Path $repoRoot $ProtocolPath
}
if (-not (Test-Path -LiteralPath $resolvedProtocolPath)) {
    throw "Protocol file not found: $ProtocolPath"
}

$protocolMarkdown = Get-Content -LiteralPath $resolvedProtocolPath -Raw
$query = Get-PubMedQuery -Markdown $protocolMarkdown
$searchTitle = Get-ProtocolValue -Markdown $protocolMarkdown -Name "Search title"
if ([string]::IsNullOrWhiteSpace($searchTitle)) {
    $searchTitle = [System.IO.Path]::GetFileNameWithoutExtension($resolvedProtocolPath)
}

$protocolMaxResults = Get-ProtocolValue -Markdown $protocolMarkdown -Name "Max results"
if ($protocolMaxResults -match "^\d+$" -and $MaxResults -eq 50) {
    $MaxResults = [int]$protocolMaxResults
}
if ($MaxResults -lt 1) {
    throw "MaxResults must be at least 1."
}
if ($MaxResults -gt 500) {
    throw "MaxResults is capped at 500 for the first PubMed workflow."
}

$protocolSort = Get-ProtocolValue -Markdown $protocolMarkdown -Name "Sort"
if ($protocolSort -in @("relevance", "pub date", "most recent") -and $Sort -eq "relevance") {
    $Sort = $protocolSort
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$slug = Convert-ToSlug -Value $searchTitle
$workingDir = Join-Path $projectRoot "working"
New-Item -ItemType Directory -Path $workingDir -Force | Out-Null

$resultFileName = "$dateStamp-search-results-pubmed-$slug.md"
$resultPath = Join-Path $workingDir $resultFileName
if (Test-Path -LiteralPath $resultPath) {
    $resultFileName = "$timestamp-search-results-pubmed-$slug.md"
    $resultPath = Join-Path $workingDir $resultFileName
}

$baseUri = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
$commonParams = @{
    db = "pubmed"
    tool = "agentic_workspace_literature_search"
    retmode = "json"
}
if ($env:NCBI_EMAIL) {
    $commonParams.email = $env:NCBI_EMAIL
}
if ($env:NCBI_API_KEY) {
    $commonParams.api_key = $env:NCBI_API_KEY
}

$queryParams = $commonParams.Clone()
$queryParams.term = $query
$queryParams.retmax = [string]$MaxResults
$queryParams.sort = $Sort

$encodedSearchParams = ($queryParams.GetEnumerator() | ForEach-Object {
    "{0}={1}" -f [uri]::EscapeDataString([string]$_.Key), [uri]::EscapeDataString([string]$_.Value)
}) -join "&"

$searchUri = "$baseUri/esearch.fcgi?$encodedSearchParams"
$searchResponse = Invoke-NcbiRequest -Uri $searchUri
$idList = @($searchResponse.esearchresult.idlist)
$hitCount = [int64]$searchResponse.esearchresult.count
$queryTranslation = [string]$searchResponse.esearchresult.querytranslation

$records = @()
if ($idList.Count -gt 0) {
    $fetchChunkSize = 100
    $articleNodes = @()
    for ($offset = 0; $offset -lt $idList.Count; $offset += $fetchChunkSize) {
        $lastIndex = [Math]::Min($offset + $fetchChunkSize - 1, $idList.Count - 1)
        $chunkIds = @($idList[$offset..$lastIndex])
        $fetchParams = $commonParams.Clone()
        $fetchParams.Remove("retmode")
        $fetchParams.id = ($chunkIds -join ",")
        $fetchParams.retmode = "xml"
        $encodedFetchParams = ($fetchParams.GetEnumerator() | ForEach-Object {
            "{0}={1}" -f [uri]::EscapeDataString([string]$_.Key), [uri]::EscapeDataString([string]$_.Value)
        }) -join "&"
        $fetchUri = "$baseUri/efetch.fcgi?$encodedFetchParams"
        $fetchText = Invoke-WebRequest -Uri $fetchUri -Headers @{ "User-Agent" = "agentic-workspace-pubmed-search/1.0" } -UseBasicParsing
        [xml]$fetchXml = $fetchText.Content
        $articleNodes += @($fetchXml.SelectNodes("//*[local-name()='PubmedArticle']"))
        if ($lastIndex -lt ($idList.Count - 1)) {
            Start-Sleep -Milliseconds 1100
        }
    }
    $records = @($articleNodes | ForEach-Object { Convert-PubMedArticle -Article $_ })
}

$relativeProtocolPath = Get-RepoRelativePath -RepoRoot $repoRoot -Path $resolvedProtocolPath
$relativeResultPath = Get-RepoRelativePath -RepoRoot $repoRoot -Path $resultPath
$tick = [string]([char]96)
$fence = $tick * 3
$protocolFence = $tick * 4

$tableRows = if ($records.Count -gt 0) {
    $records | ForEach-Object {
        "| $($_.PMID) | $($_.Title -replace '\|', '/') | $($_.PubDate -replace '\|', '/') | $($_.JournalAbbrev -replace '\|', '/') | [PubMed]($($_.PubMedUrl)) | Unscreened |"
    }
} else {
    @("| None | No PubMed records returned |  |  |  |  |")
}

$detailBlocks = if ($records.Count -gt 0) {
    $index = 0
    $records | ForEach-Object {
        $index += 1
        @(
            "### R$index. $($_.Title)",
            "",
            "- PMID: $($_.PMID)",
            "- DOI: $(Format-Value -Value $_.DOI)",
            "- PMCID: $(Format-Value -Value $_.PMCID)",
            "- PubMed: $($_.PubMedUrl)",
            "- Journal: $(Format-Value -Value $_.Journal)",
            "- Publication date: $(Format-Value -Value $_.PubDate)",
            "- Authors: $(Format-Value -Value $_.Authors)",
            "- Publication types: $(Format-Value -Value $_.PublicationTypes)",
            "- MeSH terms: $(Format-Value -Value $_.Mesh)",
            "- Relevance class: ${tick}Unscreened${tick}",
            "- Inclusion rationale: ${tick}Not yet screened${tick}",
            "- Exclusion rationale: ${tick}Not yet screened${tick}",
            "- User or collaborator connection: ${tick}Unclear${tick}",
            "- Citation verification: ${tick}PubMed E-utilities record retrieved $dateStamp${tick}",
            "",
            "#### Abstract",
            "",
            "$(Format-Value -Value $_.Abstract)"
        ) -join "`n"
    }
} else {
    @("No detailed records returned.")
}

$resultMarkdown = @(
    "# PubMed Search Results: $searchTitle",
    "",
    "- Date searched: $dateStamp",
    "- Timestamp: $timestamp",
    "- Project: ${tick}$Project${tick}",
    "- Run mode: ${tick}$RunMode${tick}",
    "- Search agent: ${tick}pubmed_literature_search${tick}",
    "- Protocol: ${tick}$relativeProtocolPath${tick}",
    "- Database: PubMed via NCBI E-utilities",
    "- Hit count: $hitCount",
    "- Returned records: $($records.Count)",
    "- Max results requested: $MaxResults",
    "- Sort: ${tick}$Sort${tick}",
    "- Status: ${tick}Working search results${tick}",
    "",
    "## Query",
    "",
    "${fence}text",
    $query,
    $fence,
    "",
    "## PubMed Query Translation",
    "",
    "${fence}text",
    $queryTranslation,
    $fence,
    "",
    "## Protocol Snapshot",
    "",
    "${protocolFence}markdown",
    $protocolMarkdown.Trim(),
    $protocolFence,
    "",
    "## Result Table",
    "",
    "| PMID | Title | Date | Journal | Link | Screening status |",
    "|---|---|---|---|---|---|",
    ($tableRows -join "`n"),
    "",
    "## Detailed Records",
    "",
    ($detailBlocks -join "`n`n"),
    "",
    "## Screening Notes",
    "",
    "- Directly on-point:",
    "- Adjacent but useful:",
    "- Background only:",
    "- Excluded:",
    "",
    "## Synthesis Handoff",
    "",
    "Pass this file to ${tick}synthesis_agent${tick} only after confirming that the result set is the intended search output. The Synthesis Agent should treat this as working evidence, not approved memory."
) -join "`n"

Set-Content -LiteralPath $resultPath -Value $resultMarkdown

$logsPath = Join-Path $projectRoot "logs\activity.md"
if (Test-Path -LiteralPath $logsPath) {
    Add-LineIfMissing -Path $logsPath -Line "- ${dateStamp}: PubMed literature search workflow wrote [working/$resultFileName](../working/$resultFileName) from ${tick}$relativeProtocolPath${tick}, returning $($records.Count) of $hitCount records."
}

$runRegisterPath = Join-Path $repoRoot "workspace\runs\agent-runs.md"
if (Test-Path -LiteralPath $runRegisterPath) {
    $runEntry = @(
        "",
        "### ${dateStamp}: PubMed Literature Search - $searchTitle",
        "",
        "- Project: ${tick}$Project${tick}",
        "- Agent mode: ${tick}pubmed_literature_search${tick}",
        "- Input: ${tick}$relativeProtocolPath${tick}",
        "- Output: ${tick}$relativeResultPath${tick}",
        "- Status: results returned to ${tick}working/${tick} for review",
        "- Follow-up: pass the search-results note to ${tick}synthesis_agent${tick} before deciding what, if anything, should be promoted to ${tick}approved/${tick}"
    ) -join "`n"
    Add-Content -LiteralPath $runRegisterPath -Value $runEntry
}

Write-Host "Created $resultPath"
Write-Host "PubMed hit count: $hitCount"
Write-Host "Returned records: $($records.Count)"

[pscustomobject]@{
    Project = $Project
    ProtocolPath = $relativeProtocolPath
    ResultPath = $relativeResultPath
    SearchTitle = $searchTitle
    HitCount = $hitCount
    ReturnedRecords = $records.Count
    Query = $query
} | ConvertTo-Json -Compress
