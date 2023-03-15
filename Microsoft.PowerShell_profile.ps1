$lambda = "λ"

$paths = @(
"C:\WINDOWS"
"C:\WINDOWS\System32\OpenSSH\"
"C:\WINDOWS\System32\Wbem"
"C:\WINDOWS\System32\WindowsPowerShell\v1.0\"
"C:\WINDOWS\system32"
"C:\WINDOWS\system32\config\systemprofile\AppData\Local\Microsoft\WindowsApps"
"C:\Program Files\Amazon\AWSCLIV2\"
"C:\Program Files\Docker\Docker\resources\bin"
"C:\Program Files\Git\cmd"
"C:\Program Files\JetBrains\DataGrip 2021.1.2\bin"
"C:\Program Files\JetBrains\JetBrains Rider 2022.1.2\bin"
"C:\Program Files\JetBrains\PyCharm 2021.1.2\bin"
"C:\Program Files\NVIDIA Corporation\NVIDIA NvDLISR"
"C:\Program Files\PowerShell\7"
"C:\Program Files\Razer Chroma SDK\bin"
"C:\Program Files\Razer\ChromaBroadcast\bin"
"C:\Program Files\dotnet\"
"C:\Program Files\nodejs"
"C:\Program Files\nu\bin\"
"C:\ProgramData\DockerDesktop\version-bin"
"C:\ProgramData\chocolatey\bin"
"C:\Program Files (x86)\Common Files\Oracle\Java\javapath"
"C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common"
"C:\Program Files (x86)\Razer Chroma SDK\bin"
"C:\Program Files (x86)\Razer\ChromaBroadcast\bin"
"C:\Users\jeff\.amplify\bin"
"C:\Users\jeff\.cargo\bin"
"C:\Users\jeff\.dotnet\tools"
"C:\Users\jeff\.dotnet\tools"
"C:\Users\jeff\.pyenv\pyenv-win\bin"
"C:\Users\jeff\.pyenv\pyenv-win\shims"
"C:\Users\jeff\AppData\Local\JetBrains\Toolbox\scripts"
"C:\Users\jeff\AppData\Local\Microsoft\WindowsApps"
"C:\Users\jeff\AppData\Local\Programs\Hyper\resources\bin"
"C:\Users\jeff\AppData\Local\Programs\Microsoft VS Code\bin"
"C:\Users\jeff\AppData\Roaming\nvm"
"C:\Users\jeff\bin"
"C:\Users\jeff\scoop\shims"
"C:\tools\neovim\nvim-win64\bin"
"c:\programdata\nvm"
".\node_modules\.bin"
)
$env:path = ""
foreach ($p in $paths) {
    $env:path+= $p + ";"
}

try {
    write-host 'creating docker aliases'


    new-alias vim nvim

    function path { $env:PATH -split ';' }

    # stop all running containers
    function dockerStopAll { docker stop (docker ps -q) }
    new-alias docker-stop-all dockerStopAll
    new-alias dsa docker-stop-all

    # remove all containers
    function dockerRmContainers { docker rm (docker ps -aq) }
    new-alias docker-rm-containers dockerRmContainers
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
        # & docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' $id
        & docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $id
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

    function Docker-Help {
        write-host dip `id` - get container ip address
        write-host d2h `name` - add a container to hosts file
        write-host drmf - remove all containers
        write-host drm - remove all stoped containers
        write-host dsa - docker stop all
        write-host docker-rm-containers
        write-host docker-rm-images
        write-host docker-rm-volumes
    }
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

#$env:Path += ';.\node_modules\.bin'

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

function grep2 {
    $input | out-string -stream | select-string $args
}

function grep($filespec, $pattern) {
    Get-ChildItem -Recurse $filespec | Select-String $pattern | Select-Object -Unique Path
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
    echo "docker run --rm -it -e USER=dev -p ${port}:${port} -v ${PWD}:/code --network="host" $lang $args"
    docker run --rm -it -e USER=dev -p ${port}:${port} -v ${PWD}:/code --network="host" $lang $args
}

# import-module posh-git
# Import-Module oh-my-posh

# $GitPromptSettings.DefaultPromptSuffix = '`n> '
# $GitPromptSettings.DefaultPromptSuffix = "`nλ "
# $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true

# #Set-Theme Paradox
# #Set-Theme Honukai
# Set-Theme Powerlevel10k-Lean
# $ThemeSettings.DoubleCommandLine = 1

Invoke-Expression (&starship init powershell)

function nginx-up {
    docker run --name nginx-static -v /static/content:/usr/share/nginx/html:ro -d --rm -p 8080:80 nginx
}

function copy-ec2 {
    rsync -Pav -e "ssh -i ~/my-ec2-key.pem" --progress --remove-source-files ec2-user@EC2_INSTANCE_IP: { /files } ~/Downloads/files
}

function tar-help {
    echo pack one directory as archive = tar -cvf arch.tar dir
    echo pack directory hierarchy = tar -cvf arch.tar -C dir/di2/dir3 .
    echo gzip it = tar -cvzf arch.tar.gz dir
    echo unpack it = tar -xvzf arch.tar.gz
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Import-Module PSColor

# default colors
# https://github.com/Davlind/PSColor
# $global:PSColor = @{
#     File = @{
#         Default    = @{ Color = 'White' }
#         Directory  = @{ Color = 'Cyan'}
#         Hidden     = @{ Color = 'DarkGray'; Pattern = '^\.' }
#         Code       = @{ Color = 'Magenta'; Pattern = '\.(java|c|cpp|cs|js|css|html)$' }
#         Executable = @{ Color = 'Red'; Pattern = '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$' }
#         Text       = @{ Color = 'Yellow'; Pattern = '\.(txt|cfg|conf|ini|csv|log|config|xml|yml|md|markdown)$' }
#         Compressed = @{ Color = 'Green'; Pattern = '\.(zip|tar|gz|rar|jar|war)$' }
#     }
#     Service = @{
#         Default = @{ Color = 'White' }
#         Running = @{ Color = 'DarkGreen' }
#         Stopped = @{ Color = 'DarkRed' }
#     }
#     Match = @{
#         Default    = @{ Color = 'White' }
#         Path       = @{ Color = 'Cyan'}
#         LineNumber = @{ Color = 'Yellow' }
#         Line       = @{ Color = 'White' }
#     }
# 	NoMatch = @{
#         Default    = @{ Color = 'White' }
#         Path       = @{ Color = 'Cyan'}
#         LineNumber = @{ Color = 'Yellow' }
#         Line       = @{ Color = 'White' }
#     }
# }


