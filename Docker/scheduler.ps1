################# Functions ###################
Write-Host "######################################################"
Write-Host "PS-Scheduler Starting up..."
if ($ENV:PSSCHEDULERMODULES) {
    Write-Host "Checking modules are installed.."
    $InstalledModules = Get-InstalledModule
    $InstalledModules | Format-Table -AutoSize
    foreach ($Module in ($ENV:PSSCHEDULERMODULES).Split(',')) {
        if ($Module -notin $InstalledModules.Name) {
            Write-Host "Installing Missing Module $($Module).."
	    Install-Module $Module -Force
        }
    }
}

if ($ENV:PSSCHEDULERDEBUG -eq "true") {
  Write-Host "Debug logging is enabled!"
  $DebugPreference = 'Continue'
} else {
  $DebugPreference = 'SilentlyContinue'
}

function Get-ConfigFile ($filePath)
{
    $ini = @{}
    switch -regex -file $filePath
    {
        “^\[(.+)\]” # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        “^(;.*)$” # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value.trim()
        }
        “(.+?)\s*=(.*)” # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value.trim()
        }
    }
    return $ini
}

function Get-WeekOfMonth($Date) {
    [Math]::Ceiling($Date.Day / 7)
}

function CheckSchedule($Config) {

    $Now = Get-Date
    $NowString = "$($Now.ToString('dd/MM/yy HH:mm:ss')) - $($Config.JobInfo.JobName):"
    $Trigger = $false

    ## Check Month of Year
    if (((Get-Culture).DateTimeFormat.GetMonthName($Now.Month)) -in ($Config.Schedule.MonthsOfYear.Split(',')) -or $Config.Schedule.MonthsOfYear -eq "all") {
        Write-Debug "$NowString Matched Month of Year" 
        $MonthTrigger = $true
    } else {
        Write-Debug "$NowString Did not match Month of Year" 
        $MonthTrigger = $false
    }

    ## Check Week of Month
    if ([Int](Get-WeekOfMonth($Now)) -in ($Config.Schedule.WeeksOfMonth.Split(',')) -or $Config.Schedule.WeeksOfMonth -eq "all") {
        Write-Debug "$NowString Matched Week of Month" 
        $WeekTrigger = $true
    } else {
        Write-Debug "$NowString Did not match Week of Month" 
        $WeekTrigger = $false
    }

    ## Check Day of Week
    if ($Now.DayOfWeek -in ($Config.Schedule.DaysOfWeek.Split(',')) -or $Config.Schedule.DaysOfWeek -eq "all") {
        Write-Debug "$NowString Matched Day of Week" 
        $DayTrigger = $true
    } else {
        Write-Debug "$NowString Did not match Day of Week" 
        $DayTrigger = $false
    }

    ## Check Hour of the Day
    if ($Now.Hour -in ($Config.Schedule.HoursOfDay.Split(',')) -or $Config.Schedule.HoursOfDay -eq "all") {
        Write-Debug "$NowString Matched Hour of the Day" 
        $HourTrigger = $true
    } else {
        Write-Debug "$NowString Did not match Hour of the Day" 
        $HourTrigger = $false
    }

    ## Check Minute of the Hour
    if ($Now.Minute -in ($Config.Schedule.MinutesOfHour.Split(',')) -or $Config.Schedule.MinutesOfHour -eq "all") {
        Write-Debug "$NowString Matched Minute of the Hour" 
        $MinuteTrigger = $true
    } else {
        Write-Debug "$NowString Did not match Minute of the Hour" 
        $MinuteTrigger = $false
    }

    if ($MonthTrigger -and $WeekTrigger -and $DayTrigger -and $HourTrigger -and $MinuteTrigger) {
        return $true
    } else {
	return $false
    }
}

################################################

Write-Host "PS-Scheduler Startup Complete!"
Write-Host "######################################################`n"

while ($true) {
    $Now = Get-Date
    $NowString = $Now.ToString('dd/MM/yy HH:mm:ss')
    Write-Debug "$NowString - Keepalive"
    foreach ($CompletedJob in (Get-Job -State "Completed")) {
      Write-Host "$NowString - $($CompletedJob.Name): Job Completed. Output below;`n"
      $CompletedJob | Receive-Job
      $CompletedJob | Remove-Job
      Write-Host ""
    }
  
    $ScriptDirs = Get-ChildItem '/scripts' -Directory
  
    foreach ($ScriptDir in $ScriptDirs) {
      if (Test-Path "$($ScriptDir.FullName)/init.ps1") {
        if (Test-Path "$($ScriptDir.FullName)/config.ini") {
          $ConfigFile = Get-ConfigFile "$($ScriptDir.FullName)/config.ini"
          if ($ConfigFile) {
            $JobName = $ConfigFile.JobInfo.JobName
            if (!$JobName) {
              $JobName = $($ScriptDir.Name)
            }
	    $RunOnce = $ConfigFile.Schedule.RunOnce
            if ($RunOnce -ne 'true' -or ($RunOnce -eq 'true' -and !(Test-Path "$($ScriptDir.FullName)/runonce.flag"))) {
              if (CheckSchedule($ConfigFile)) {
                Write-Host "$NowString - $($JobName): Triggering scheduled job."
                if ($JobName -in (Get-Job).Name) {
                  Write-Host "$NowString - $($JobName): Error! Job is still running and cannot be started twice."
                } else {
                  $Job = Start-Job -FilePath "$($ScriptDir.FullName)/init.ps1" -Name $JobName
	          if ($RunOnce -eq 'true') {
                    New-Item "$($ScriptDir.FullName)/runonce.flag" | Out-Null
		  }
                }
              }
            }
          } else {
            Write-Host "$NowString - Error reading Config.ini file, skipping this directory ($($ScriptDir.Name)).."
          }
        } else {
            Write-Debug "$NowString - Config.ini not found, skipping this directory ($($ScriptDir.Name)).."
        }
      } else {
        Write-Debug "$NowString - Init.ps1 not found, skipping this directory ($($ScriptDir.Name)).."
      }
    }
    Wait-Event -Timeout (60 - $Now.Second)
}
