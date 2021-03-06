[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

function ChangeChildControlColor($control, [System.Drawing.Color]$foreColor, [System.Drawing.Color]$backColor)
{
    if ($control -eq $null)
    {
        return
    }
 
    $control.Controls | ForEach-Object {
        if ($_ -ne $null)
        {
            if (($_ | Get-Member -Name "BackColor") -ne $null)
            {
                $_.BackColor = $backColor
            }
            if (($_ | Get-Member -Name "ForeColor") -ne $null)
            {
                $_.ForeColor = $foreColor
            }
        }
 
        ChangeChildControlColor $_ $foreColor $backColor
    }
}
 
function Set-ColorScheme([System.Drawing.Color]$ForeColor, [System.Drawing.Color]$BackColor)
{
    $seMain = $PGSE.GetType().GetMember("_seMain", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)[0].GetValue($PGSE)
 
    ChangeChildControlColor $seMain $foreColor $backColor
 
    $backColorFill = New-Object -TypeName ActiproSoftware.Drawing.SolidColorBackgroundFill -ArgumentList $backColor
    $foreColorFill = New-Object -TypeName ActiproSoftware.Drawing.SolidColorBackgroundFill -ArgumentList $foreColor
 
    $PGSE.ToolWindows | ForEach-Object {
        $_.Control.BackColor = $backColor
        $_.Control.ForeColor = $foreColor
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerBackgroundFill = $backColorFill
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerTitleBarActiveBackgroundFill   = $backColorFill
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerTitleBarActiveForeColor = $foreColor
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerTitleBarInactiveBackgroundFill   = $backColorFill
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerTitleBarInactiveForeColor = $foreColor
        $_.Control.Parent.DockManager.DockRendererResolved.DockObjectSplitterBackgroundFill = $backColorFill
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerTitleBarButtonNormalBackgroundFill = $backColorFill
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerTitleBarActiveButtonNormalGlyphColor = $foreColor
        $_.Control.Parent.DockManager.DockRendererResolved.DockContainerTitleBarInactiveButtonNormalGlyphColor = $foreColor
        $_.Control.Parent.DockManager.DockRendererResolved | Get-Member
 
        ChangeChildControlColor $_ $foreColor $backColor
    }
 
    $PGSE.Toolbars | Select-Object -First 1 | ForEach-Object {
        $val = $_.GetType().GetMember("OriginalObject", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)[0].GetValue($_)
        $val.RendererResolved.BarDefaultAlternateForeColor = $foreColor
        $val.RendererResolved.DockAreaBackgroundFill = $backColorFill
        $val.RendererResolved.ToolBarDefaultFloatingTitleBarBackgroundFill = $backColorFill
        $val.RendererResolved.BarDefaultForeColor = $foreColor
        $val.RendererResolved.MenuDefaultBackgroundFill = $backColorFill
        $val.RendererResolved.ToolBarDefaultBackgroundFill = $backColorFill
        ChangeChildControlColor $val $foreColor $backColor
    }
 
    $PGSE.DocumentWindows | Select-Object -First 1 | ForEach-Object {
        $val = $_.Document.GetType().GetMember("_editor", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)[0].GetValue($_.Document)
        $val.Parent.Parent.Parent.RendererResolved.TabStripTabContainerBackgroundFill = $backColorFill
        $val.RendererResolved.TextAreaBackgroundFill = $backColorFill
        $val.RendererResolved.IndicatorMarginBackgroundFill = $backColorFill
        $val.RendererResolved.LineNumberMarginBackgroundFill = $backColorFill
        $val.RendererResolved.SplitterBackgroundFill = $backColorFill
        $val.RendererResolved.IndicatorMarginBackgroundFill = $backColorFill
        $val.RendererResolved.ScrollBarBlockBackgroundFill = $backColorFill
    }
}