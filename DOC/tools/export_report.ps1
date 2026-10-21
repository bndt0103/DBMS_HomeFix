$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$docPath = Join-Path $repo 'DOC/Nhom08_BaoCao_HQTCSDL_HomeFix.docx'
$pdfPath = Join-Path $repo 'DOC/Nhom08_BaoCao_HQTCSDL_HomeFix.pdf'
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null
try {
    Write-Output 'Opening report'
    $doc = $word.Documents.Open($docPath, $false, $false)
    Write-Output 'Repaginating'
    $doc.Repaginate()
    foreach ($toc in $doc.TablesOfContents) { $toc.Update() }
    foreach ($tof in $doc.TablesOfFigures) { $tof.Update() }
    Write-Output 'Updating fields'
    $doc.Fields.Update() | Out-Null
    $doc.Repaginate()
    foreach ($toc in $doc.TablesOfContents) { $toc.UpdatePageNumbers() }
    foreach ($tof in $doc.TablesOfFigures) { $tof.UpdatePageNumbers() }
    $doc.Save()
    Write-Output 'Exporting PDF'
    $doc.ExportAsFixedFormat($pdfPath, 17)
    Write-Output ('Exported PDF; pages=' + $doc.ComputeStatistics(2))
} finally {
    if ($null -ne $doc) { $doc.Close(0) }
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
