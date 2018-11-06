[environment]::NewLine * 5

"cleanup for interactive sessions"
for ($i=0;$i -lt @(Get-HierarchyObject).count;$i++) {
    (Get-HierarchyObject)[0].RemoveObject()
    }
Remove-Variable root -ErrorAction SilentlyContinue

write-host "this will be the root of the hierarchy"
'it will be assigned to $root variable so it can be easily referenced later'
$root = New-HierarchyObject -Name 'root'
$root

'this will be subordinate nodes'
'if CreateVariable switch is used while creating node, global PowerShell variable would be created, so this node could be later found, without manually assigning it to a variable'
New-HierarchyObject -name Level1SubA -DependOn $root

'if you do not want to output nodes to pipeline wrap them to [void]() call or pipe it to Out-Null or assign to a (temporary) variable'
[void](New-HierarchyObject -name Level1SubB -DependOn $root)

''
'if you created a node with CreateVariable Switch you can later find this node using Get-HierarchyObject function and filtering it by its properties'
'like here we are creating new node which is subordinate to a node with name "Level1SubA":'
New-HierarchyObject -name Level2SubA_A -DependOn (Get-HierarchyObject | ? {$_.name -eq 'Level1SubA'})

'there are a couple of properties to query:'
$root | Get-Member -MemberType Property | Format-Table

'Name, Type, SubType and Value are just strings, use them as see fit'
'Guid is ... well guid, unique identificator of the node, so even if there was two nodes created with same name, but in different position in hierarchy, they still will have an unique identity'
$root.Guid
''
'DependOn is an array property which tells on which nodes (their guids specifically) this node is depend, or in another words, have child -> parent relationship'
'root node obviously have none:'
$root.DependOn.Count
'but "Level1SubA" has one'
(Get-HierarchyObject | ? {$_.name -eq 'Level1SubA'}).DependOn.Count
'which is that of the $root node:'
(Get-HierarchyObject | ? {$_.name -eq 'Level1SubA'}).DependOn[0].Guid -eq $root.Guid.Guid
''
'DependedBy is a similar property, but for parent -> child relationship'
'$root object now has two of them:'
$root.DependedBy
''
'You can change these relationships manually, calling AddDependOn() and RemoveDependOn() methods'
(Get-HierarchyObject | ? {$_.name -eq 'Level2SubA_A'}).AddDependOn($root)
''
'Now $root node should have 3 DependedBy references:'
$root.DependedBy.Count
'And "Level2SubA_A" has two guids in DependOn property:'
(Get-HierarchyObject | ? {$_.name -eq 'Level2SubA_A'}) | Select-Object DependOn
''
'There is another property, Links, which can be used for direct connections between nodes anywhere in (and out of) hierarchy'
'This property is used through AddLink() and RemoveLink() methods'
$anotherRoot = New-HierarchyObject -Name 'AnotherRoot'
(Get-HierarchyObject | ? {$_.name -eq 'Level2SubA_A'}).AddLink($anotherRoot)
(Get-HierarchyObject | ? {$_.name -eq 'Level2SubA_A'})

'There are a couple of helper functions:'
'Get-HierarchyObject retrieves all variables of HierarchyObject type'
(Get-HierarchyObject).Count
Get-HierarchyObject | Format-Table

'Remove-DOVariable does what it says (and for now cleans ALL of them (!))'
''
'Walk-HierarchyObject will walk the tree of the DepednedBy nodes'
[void](New-HierarchyObject -name Level2SubB_A -DependOn ((Get-HierarchyObject | ? {$_.name -eq 'Level1SubB'})))
[void](New-HierarchyObject -name Level3SubB_A_A -DependOn ((Get-HierarchyObject | ? {$_.name -eq 'Level2SubB_A'})))
Walk-HierarchyObject (Get-HierarchyObject | ? {$_.name -eq 'Level1SubB'}) 

#'Get-DOLinkedObjects retrieves linked *Objects* (not their guids)'
#$anotherRoot | Get-DOLinkedObjects 

