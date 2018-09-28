Import-Module -Name ".\WASP\WASP.dll"
Add-Type -AssemblyName System.Windows.Forms

$viewer = "C:\Program Files\RealVNC\VNC Viewer\vncviewer.exe"
$processname = "vncviewer"
$devicename = "\\.\DISPLAY2"
$windows_per_row = 3


$dockers = @{
    chrome1 = "10.30.10.20:49338"
    chrome2 = "10.30.10.20:49339"
    chrome3 = "10.30.10.20:49340"
    chrome4 = "10.30.10.20:49341"
    chrome5 = "10.30.10.20:49342"
    chrome6 = "10.30.10.20:49343"
    chrome7 = "10.30.10.20:49344"
    chrome8 = "10.30.10.20:49345"
    <#  
    test1 = "127.0.0.1:5901"
    test2 = "127.0.0.1:5901"
    test3 = "127.0.0.1:5901"
    test4 = "127.0.0.1:5901"
    #>
}

<#
$existing = Get-Process $processname
if ($existing) {
    echo "Killing existing windows ..."
    $existing | ForEach-Object {
        $_.CloseMainWindow();
    }
}
#>

Function clamp($value) {
    if ($value -eq 0) {
        1;
     }
     else {
        $value;
    }
}

$display = [System.Windows.Forms.Screen]::AllScreens | Where-Object { $_.DeviceName -eq $devicename }

$leftfix = -3;
$topfix = -3;
$widthfix = 6;
$heightfix = 4;

$i = 0;
try {
    echo "Probing for Docker processes with VNC ..."
    while (1) {

        $dockers.Keys | ForEach-Object {
            $vncviewer = Select-Window -Title "*${_}*"
            # Is running?
            if ($vncviewer -eq $null) {
                echo "$_ has no vncviewer running, check if TCP port open ..."
                # Is TCP port open?
                $connection_test = Test-NetConnection -ComputerName $dockers[$_].Split(":")[0] -Port $dockers[$_].Split(":")[1]
                if ($connection_test.TcpTestSucceeded) {
                    echo "TCP port open! Starting vncviewer"
                    Start-Process -FilePath $viewer -ArgumentList "-config configs\${_}.vnc"
                }
                else {
                    echo "TCP port closed, waiting for tests to resume" 
                }
            }
            else {
                #echo "$_ is already opened"
            }
        }


        $num_windows = (Get-Process $processname).Length

        if ($num_windows -gt 0) {

            $num_rows = [Math]::Ceiling($num_windows / $windows_per_row)
            $width_per_window = $display.WorkingArea.Width / $windows_per_row
            $height_per_window =  $display.WorkingArea.Height / $num_rows
            $xoffset = $display.WorkingArea.X
            $yoffset = $display.WorkingArea.Y

            #echo "rows:$num_rows width:$width_per_window height:$heigh_per_window"

            Select-Window -ProcessName $processname | ForEach-Object {
                if ($i % $windows_per_row -eq 0) {       
                    $left = $xoffset - $width_per_window
                }
                $left += $width_per_window
                $top =  [Math]::Floor($i / $windows_per_row) * $height_per_window + $yoffset

                $thisleft = clamp($left + $leftfix);    
                $thistop = clamp($top + $topfix);
        
                $_ | Set-WindowPosition -Left $thisleft -Top $thistop -Width ($width_per_window + $widthfix) -Height ($height_per_window + $heightfix)
                $i++
                
                #echo "Window ${i}: left:$thisleft top:$thistop width:$width_per_window height:$height_per_window"
            }
            $i = 0;
        }
        Sleep 1
    }
}
finally {
    <# FIXME! This only closes one window
    (Get-Process $processname) | ForEach-Object {
        $_.CloseMainWindow();
    }
    #>
}
