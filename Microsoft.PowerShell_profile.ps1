
$lambda = "λ"

try {
    write-host 'creating docker aliases'

    # stop all running containers
    function dockerStopAll { docker stop (docker ps -q) }
    new-alias docker-stop-all dockerStopAll
    new-alias dsa docker-stop-all

    # remove all containers
    function dockerRmContainers { docker rm (docker ps -aq) }
    new-alias docker-rm-containers dockerRmContainersex
    # remove all image
    function dockerRemoveImages { docker rmi (docker images -q) }
    new-alias docker-rm-images dockerRemoveImages

    function dockerRemoveVolumes { docker volume rm (docker volume ls -q) }
    new-alias docker-rm-volumes dockerRemoveVolumes

    function Remove-StoppedContainers {
        docker container rm $(docker container ls -q)
    }
    Set-Alias drm  Remove-StoppedContainers

    function Remove-AllContainers {
        docker container rm -f $(docker container ls -aq)
    }
    Set-Alias drmf  Remove-AllContainers

    function Get-ContainerIPAddress {
        param (
            [string] $id
        )
        & docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' $id
    }
    Set-Alias dip  Get-ContainerIPAddress

    function Add-ContainerIpToHosts {
        param (
            [string] $name
        )
        $ip = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' $name
        $newEntry = "$ip  $name  #added by d2h# `r`n"
        $path = 'C:\Windows\System32\drivers\etc\hosts'
        $newEntry + (Get-Content $path -Raw) | Set-Content $path
    }
    Set-Alias d2h  Add-ContainerIpToHosts
}
catch {
    Write-Error  $_
    write-host 'some problem with aliases'
}

function tail($path, $lines = 10) {
    Get-Content  $path -Tail $lines -Wait
}

function count($path, $recurse = 'false') {
    if ($recurse -eq 'true' -Or $recurse -eq '-r') {
        Get-ChildItem -File $path | Measure-Object | % { $_.Count }
    }
    else {
        Get-ChildItem -Recurse $path | Measure-Object | % { $_.Count }
    }
}
Function Set-FileTime {
    param(
        [string[]]$paths,
        [bool]$only_modification = $false,
        [bool]$only_access = $false
    )

    begin {
        function updateFileSystemInfo([System.IO.FileSystemInfo]$fsInfo) {
            $datetime = Get-Date
            if ( $only_access ) {
                $fsInfo.LastAccessTime = $datetime
            }
            elseif ( $only_modification ) {
                $fsInfo.LastWriteTime = $datetime
            }
            else {
                $fsInfo.CreationTime = $datetime
                $fsInfo.LastWriteTime = $datetime
                $fsInfo.LastAccessTime = $datetime
            }
        }

        function touchExistingFile($arg) {
            if ($arg -is [System.IO.FileSystemInfo]) {
                updateFileSystemInfo($arg)
            }
            else {
                $resolvedPaths = Resolve-Path $arg
                foreach ($rpath in $resolvedPaths) {
                    if (Test-Path -type Container $rpath) {
                        $fsInfo = New-Object System.IO.DirectoryInfo($rpath)
                    }
                    else {
                        $fsInfo = New-Object System.IO.FileInfo($rpath)
                    }
                    updateFileSystemInfo($fsInfo)
                }
            }
        }

        function touchNewFile([string]$path) {
            #$null > $path
            Set-Content -Path $path -value $null;
        }
    }

    process {
        if ($_) {
            if (Test-Path $_) {
                touchExistingFile($_)
            }
            else {
                touchNewFile($_)
            }
        }
    }

    end {
        if ($paths) {
            foreach ($path in $paths) {
                if (Test-Path $path) {
                    touchExistingFile($path)
                }
                else {
                    touchNewFile($path)
                }
            }
        }
    }
}
import-module posh-git

$GitPromptSettings.DefaultPromptSuffix = '`n> '

# $GitPromptSettings.DefaultPromptSuffix = "`nλ "
# $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true


New-Alias touch Set-FileTime
# New-Alias which Get-Command
function which($cmd) { get-command $cmd | select path }

# Setup miniconda stuff
# $Env:CONDA_EXE = "C:/Users/JLINDHOLM/AppData/Local/Continuum/miniconda3\Scripts\conda.exe"
# $Env:_CE_M = ""
# $Env:_CE_CONDA = ""
# $Env:_CONDA_ROOT = "C:/Users/JLINDHOLM/AppData/Local/Continuum/miniconda3"
# $Env:_CONDA_EXE = "C:/Users/JLINDHOLM/AppData/Local/Continuum/miniconda3\Scripts\conda.exe"

# Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1"

# if (Test-Path Function:\prompt) {
#     Rename-Item Function:\prompt CondaPromptBackup
# }
# function global:prompt() {
#     if ($Env:CONDA_PROMPT_MODIFIER) {
#         $Env:CONDA_PROMPT_MODIFIER | Write-Host -NoNewline
#     }
#     CondaPromptBackup;
# }

# $env:Path += ";" + $env:_CONDA_ROOT + "\Scripts"
# conda activate 'C:\Users\JLINDHOLM\AppData\Local\Continuum\miniconda3'

$env:Path += ';.\node_modules\.bin'

$console = $host.ui.rawui
$console.backgroundcolor = "black"
$console.foregroundcolor = "white"
# clear-host

function Remove-All-Folders($folder) {
    Get-ChildItem -Path "." -Include $folder -Recurse -File:$false | Remove-Item -Recurse -Force
}
function Remove-Node-Modules() {
    Remove-All-Folders("node_modules")
}
function Find-All($name) {
    get-childitem -Path . -Recurse -force -Include $name -ErrorAction SilentlyContinue
}

function venv { python -m venv $args }

function set-case() {
    param(
        [string[]]$paths,
        [bool]$enable = $false
    )
    foreach ($path in $paths) {
        if ($enable) {
            fsutil file setCaseSensitiveInfo $path disable
        }
        else {
            fsutil file setCaseSensitiveInfo $path disable
        }
    }
}

# setup autoenv
Import-Module ps-autoenv

function dev-here($lang, $port = 8000) {
    if ($lang -eq '') {
        echo 'usage is dev-here <container name>'
        return
    }
    $args = 'bash'
    if ($lang -eq 'python') {
        $args = "bash"
        # $args = "bash -c 'cd code && pip install -r requirements.txt && bash'"
    }
    $msg = $lang + ' opening port ' + $port + ' running ' + $args
    echo $msg
    echo "docker run --rm -it -p ${port}:${port} -v ${PWD}:/code $lang $args"
    docker run --rm -it -p ${port}:${port} -v ${PWD}:/code $lang $args
}