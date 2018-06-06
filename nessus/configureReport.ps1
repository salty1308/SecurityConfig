#need to read in a file
function Get-ExcelFile
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $FilePath
    )
    #create a excel object and open the workbook
    $Excel=new-object -com excel.application
    $WorkBook=$Excel.workbooks.open($FilePath)

    Write-Host -ForegroundColor Green "XLSX Loaded and the following sheets have been Identified"
    #get the worksheets to read in the values from those sheets
    $worksheets = @()
    $worksheetsIndex = @()
    foreach ($item in $WorkBook.Sheets)
    {
        $worksheets += $item.Name
        $worksheetsIndex = $item.Index
        Write-Host -ForegroundColor Yellow $item.Name
    }

    $worksheet = $WorkBook.Sheets.Item("host_scan_data")

    $WorksheetRange = $workSheet.UsedRange
    $RowCount = $WorksheetRange.Rows.Count
    $ColumnCount = $WorksheetRange.Columns.Count
    Write-Host -ForegroundColor Yellow "RowCount:" $RowCount
    Write-Host -ForegroundColor Yellow "ColumnCount" $ColumnCount

    #create a hastable
    $hashTable = @{}
    for ($i = 1; $i -lt $ColumnCount; $i++)
    { 
        $hashTable["$($worksheet.Rows.Cells.item(2,$i).value2)"] = @()
        for ($r = 1; $r -lt $RowCount; $r++)
        {
            $hashTable["$($worksheet.Rows.Cells.item(2,$i).value2)"] += "$($worksheet.Rows.Cells.item($r,$i).value2)"
        }
           
    }

    pause
    #close the excel afterwards
    $Excel.Workbooks.Close()
}

$filePATH = ""
