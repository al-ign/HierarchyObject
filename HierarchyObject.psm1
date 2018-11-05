class HierarchyObject {
    [string] $Name
    [string] $Value 
    [string] $Type 
    [string] $SubType
    [guid] $Guid
    [array] $Links
    [array] $DependOn
    [array] $DependedBy
    [System.Collections.ArrayList] $Tags
    hidden static [System.Collections.ArrayList] $AllObjects
        
    #constructor
    HierarchyObject() {
        $this.Guid = New-Guid
        try {
            [HierarchyObject]::AllObjects.add($this)
            }
        catch {
            [HierarchyObject]::AllObjects = New-Object System.Collections.ArrayList
            [HierarchyObject]::AllObjects.add($this)
            }
        }

    HierarchyObject([string]$Name) {
        $this.Guid = New-Guid
        try {
            [HierarchyObject]::AllObjects.add($this)
            }
        catch {
            [HierarchyObject]::AllObjects = New-Object System.Collections.ArrayList
            [HierarchyObject]::AllObjects.add($this)
            }
        $this.Name = $Name
        }

    HierarchyObject([string]$Name, [string]$Type) {
        $this.Guid = New-Guid
        try {
            [HierarchyObject]::AllObjects.add($this)
            }
        catch {
            [HierarchyObject]::AllObjects = New-Object System.Collections.ArrayList
            [HierarchyObject]::AllObjects.add($this)
            }
        $this.Type = $Type
        $this.Name = $Name
        }
    HierarchyObject([string]$Name, [string]$Type, [HierarchyObject[]]$DependOn) {
        $this.Guid = New-Guid
        try {
            [HierarchyObject]::AllObjects.add($this)
            }
        catch {
            [HierarchyObject]::AllObjects = New-Object System.Collections.ArrayList
            [HierarchyObject]::AllObjects.add($this)
            }
        $this.Type = $Type
        $this.Name = $Name

        $this.DependOn = ( & {
            $arrDependOn = @()

            foreach ($Dependency in $DependOn) {
                $arrDependOn += $Dependency.Guid
                $Dependency.DependedBy += $this.Guid
                }
            $arrDependOn
            })
        }

    AddDependOn ([HierarchyObject[]]$DependOn) {
        $this.DependOn = ( & {
            if ($this.DependOn -eq $null) {
                $arrDependOn = @()
                }
                else {
                $arrDependOn = @($this.DependOn)
                }

            foreach ($Dependency in $DependOn) {
                $arrDependOn += $Dependency.Guid
                $Dependency.DependedBy += $this.Guid
                }
            $arrDependOn
            })
        }

    RemoveDependOn ([HierarchyObject[]]$DependOn) {
    $this.DependOn = ( & {
        $arrDependOn = @($this.DependOn)
        foreach ($Dependency in $DependOn) {
                [array]$arrDependOn = $arrDependOn | ? {$_ -ne $Dependency.Guid}
                [array]$Dependency.DependedBy = $Dependency.DependedBy | ? {$_ -ne $this.Guid}
                }
                $arrDependOn
            })
        #$this.DependOn | ? {$_ -ne $DependOn}
        }

    AddLink ([HierarchyObject[]]$HierarchyObject) {
         
        if ($this.Links -eq $null) {
            $arrLinks = @()
            }
            else {
            $arrLinks = @($this.Links)
            }

        foreach ($Link in $HierarchyObject) {
            $arrLinks += $Link.Guid
            $Link.Links += $this.Guid
            }

        $this.Links = $arrLinks
            
        }

    RemoveLink ([HierarchyObject[]]$HierarchyObject) {

        $arrLinks = @($this.Links)

        foreach ($Link in $HierarchyObject) {
                [array]$arrLinks = $arrLinks | ? {$_ -ne $Link.Guid}
                [array]$Link.Links = $Link.Links | ? {$_ -ne $this.Guid}
                }
        $this.Links = $arrLinks
        
        }

    RemoveObject () {
        $this.RemoveLink($this)
        $this.RemoveDependOn($this)
        [HierarchyObject]::AllObjects.Remove($this)
        }

    AddTag ($Tag) {
        try {
            $this.Tags.Add($Tag)
            }
        catch {
            $this.Tags = New-Object System.Collections.ArrayList
            $this.Tags.Add($Tag)
            }
        }

    RemoveTag ($Tag) {
        try {
            $this.Tags.Remove($Tag)
            }
        catch {
            Write-Debug -Message "RemoveTag() with $Tag was requested but no such tag existed"
            }
        }

    } #end class declaration


function New-HierarchyObject {
param (
$Name,
$Type,
$DependOn,
$Value,
$SubType,
$Links
)
    $obj = New-Object HierarchyObject -ArgumentList $name,$type,$DependOn
    if ($value) {
        $obj.Value = $value
        }
    if ($SubType) {
        $obj.SubType = $SubType
        }
    if ($Links) {
        $obj.AddLink($links)
        }
    return $obj
    }

function Get-HierarchyObject {
[CmdletBinding()]
param ()
    begin {
        if ($MyInvocation.BoundParameters.Count -eq 0) {
            [HierarchyObject]::AllObjects
            }
        }
    process {
        
        }
}

function Remove-HierarchyObject {
[CmdletBinding()]
param ()
    process {
        $_.RemoveObject()
        }
}

function Walk-HierarchyObject {
[CmdletBinding(DefaultParameterSetName="Command")]
param(
    [Parameter(Mandatory=$true, 
    ParameterSetName="Command",
                   ValueFromPipeline=$true,
                   Position = 0)]
    $object,
    [parameter(Mandatory=$False, ParameterSetName="Command")]
    [array]$array,
    [parameter(Mandatory=$False, ParameterSetName="Command")]
    [switch]$DependOn,
    [parameter(Mandatory=$False, ParameterSetName="Command")]
    [string[]]$type, 
    [parameter(Mandatory=$False, ParameterSetName="Command")]
    [int]$Level = 0,
    [parameter(Mandatory=$False, ParameterSetName="Command")]
    [int]$depth,
    [Parameter(Mandatory=$true, 
    ParameterSetName="InvocationObject")]
    [hashtable]$InvokeObject
    )
    
begin {

    filter octype {
        '['+$_.type +']'+ $_.name + ':' + $_.value
    }
    filter ocvalue {
       $_.name + ':' + $_.value
    }
 
     
    if ($array.Count -eq 0) {
        [array]$array = Get-HierarchyObject
        }
    
    if ($DependOn) {
        $direction = 'DependOn'
        }
        else {
        $direction = 'DependedBy'
        }
    
    if ($PSCmdlet.ParameterSetName -eq 'Command') {
        [hashtable]$InvokeObject = @{
            Object = $object
            Array = $array
            Direction = $direction
            Type = $type
            OnlyType = $False
            Level = 0
            Depth = $depth
            }

        if ($PSBoundParameters['type']) {
            $InvokeObject.OnlyType = $true
            }

        }
      
    } #End of begin

process {
     
    if ($input) {
        $PSCmdlet.MyInvocation.MyCommand.Name + ' ' + 'Process block, I''m on input chain, ' + $input.Count + ' input objects' | Write-Debug
        $InvokeObject.object  = $input[0]
         }
      
    $InvokeObject.Level++
     
    $level = $InvokeObject.level
    $object = $InvokeObject.Object
    $direction = $InvokeObject.Direction
     
    foreach ($dependency in ($InvokeObject.Object).($InvokeObject.Direction)) {
        $InvokeObject.level = $Level
        $InvokeObject.object = $object
        $needToOutput = $false
        #'huis is: ' + ''
        $dependency =  $array | ? {$_.guid -eq $dependency}
        $InvokeObject.Direction = $direction
        if ($dependency) {
            'dep count: ' +$dependency.count | Write-Debug
            #Display dependency info if verbose
            switch ($direction) {
                'DependOn' {
                    "[^] <$($InvokeObject.Level)> $(($InvokeObject.Object) | octype) <- dependent from $($dependency | octype)" | Write-Verbose

                    }
                'DependedBy' {
                    "[v] <$($InvokeObject.Level)> $($dependency | octype) <- depends on $(($InvokeObject.Object) | octype)" | Write-Verbose
                    }
                } # end switch ($direction)

            

            if ($InvokeObject.OnlyType) {
                if ($InvokeObject.Type -contains $dependency.Type) {
                    'IO contains type' | Write-Debug
                    $needToOutput = $true
                    }
                }
                else {
                $needToOutput = $true
                }
        
            if ($needToOutput) {
                'dep output' | Write-Debug
                $dependency 
                }

            if ($InvokeObject.Level -eq $InvokeObject.Depth) {
                $shouldNotContinue = $true
                $PSCmdlet.MyInvocation.MyCommand.Name + ' ' + 'Decided to not continue' | Write-Debug 
                }

            if ($dependency.$direction -and (-not $shouldNotContinue)) {
                
                    $InvokeObject.object = $dependency
                       
                        Walk-HierarchyObject -InvokeObject $InvokeObject
                    }

            }
            else {
            'No dependency found for ' + (($InvokeObject.Object) | octype)| Write-Verbose
            }
 
        } # end foreach ($dependency in ($InvokeObject.Object).$direction) 
    }

    } # end of Walk-HierarchyObject


function Get-DOLinkedObjects {
[CmdletBinding(DefaultParameterSetName="Command")]
param(
    [Parameter(Mandatory=$true, 
    ParameterSetName="Command",
                   ValueFromPipeline=$true,
                   Position = 0)]
    [Alias('Object')]
    #[HierarchyObject]
    $HierarchyObject,
    [array]$Array
    )
begin {
    if ($Array.Count -eq 0) {
        [array]$Array = Get-DOVariable
        }
    }

process {
    foreach ($Link in $HierarchyObject.Links) {
        $Object =  $Array | ? {$_.Guid -eq $Link}
        $Object
        } # End %
    }

} # End Get-DOLinkedObjects


function Get-DOTypeParents {
param (
    $HierarchyObject
    )
    $types = Get-ConformityFunctionsWithQueryOptions
    $types | ? {$_.type -eq $HierarchyObject.Type} | % {$_.parent}
    }


function Find-DOParentByType {
param (
    [Parameter(
        Mandatory=$true)]
    $HierarchyObject,
    [int]$level = 2
    )
    begin {
    $TypeParents = Get-DOTypeParents $HierarchyObject
    }
    end {
        #[bool]$ShouldContinu
        foreach ($depth in 1..$level) {
            $parents = $HierarchyObject | Walk-HierarchyObject -DependOn -depth $depth 
            
            if ($parents.type -contains $TypeParents.Type) {
                $PSCmdlet.MyInvocation.MyCommand.Name + `
                    ': matching object found in parents for type' + $TypeParents.Type  | Write-Debug
                $parents | ? {$_.Type -contains $TypeParents.Type}
                }
                else {
                $PSCmdlet.MyInvocation.MyCommand.Name + `
                    ': no matching objects in parents for type: ' + $TypeParents.Type | Write-Debug
                
                $neighbors = $parents | Select-Object -Last 1 | Walk-HierarchyObject -depth 1 -type $TypeParents.type
                if ($neighbors) {
                    $PSCmdlet.MyInvocation.MyCommand.Name + `
                        ': matching objects found in neighbours at level : ' + $level | Write-Debug
                
                    $depth = $level
                    $neighbors
                    break
                    }
                }
            } # End %
        }
    } # End of func



if (!(get-alias nho  -ea 0)) {
    New-Alias nho New-HierarchyObject
    }

