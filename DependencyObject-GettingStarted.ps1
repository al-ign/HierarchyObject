[environment]::NewLine * 5

"cleanup for interactive sessions"
Remove-DOVariable
Remove-Variable root -ErrorAction SilentlyContinue

write-host "this will be the root of the hierarchy"
'it will be assigned to $root variable so it can be easily referenced later'
$root = New-DependencyObject -Name 'root' -CreateVariable
$root

'this will be subordinate nodes'
'if CreateVariable switch is used while creating node, global PowerShell variable would be created, so this node could be later found, without manually assigning it to a variable'
New-DependencyObject -name Level1SubA -DependOn $root -CreateVariable

'if you do not want to output nodes to pipeline wrap them to [void]() call or pipe it to Out-Null or assign to a (temporary) variable'
[void](New-DependencyObject -name Level1SubB -DependOn $root -CreateVariable)

''
'if you created a node with CreateVariable Switch you can later find this node using Get-DOVariable function and filtering it by its properties'
'like here we are creating new node which is subordinate to a node with name "Level1SubA":'
New-DependencyObject -name Level2SubA_A -DependOn (Get-DOVariable | ? {$_.name -eq 'Level1SubA'}) -CreateVariable

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
(Get-DOVariable | ? {$_.name -eq 'Level1SubA'}).DependOn.Count
'which is that of the $root node:'
(Get-DOVariable | ? {$_.name -eq 'Level1SubA'}).DependOn[0].Guid -eq $root.Guid.Guid
''
'DependedBy is a similar property, but for parent -> child relationship'
'$root object now has two of them:'
$root.DependedBy
''
'You can change these relationships manually, calling AddDependOn() and RemoveDependOn() methods'
(Get-DOVariable | ? {$_.name -eq 'Level2SubA_A'}).AddDependOn($root)
''
'Now $root node should have 3 DependedBy references:'
$root.DependedBy.Count
'And "Level2SubA_A" has two guids in DependOn property:'
(Get-DOVariable | ? {$_.name -eq 'Level2SubA_A'}) | Select-Object DependOn
''
'There is another property, Links, which can be used for direct connections between nodes anywhere in (and out of) hierarchy'
'This property is used through AddLink() and RemoveLink() methods'
$anotherRoot = New-DependencyObject -Name 'AnotherRoot' -CreateVariable
(Get-DOVariable | ? {$_.name -eq 'Level2SubA_A'}).AddLink($anotherRoot)
(Get-DOVariable | ? {$_.name -eq 'Level2SubA_A'})

'There are a couple of helper functions:'
'Get-DOVariable retrieves all variables of DependencyObject type'
(Get-DOVariable).Count
Get-DOVariable | Format-Table

'Remove-DOVariable does what it says (and for now cleans ALL of them (!))'
''
'Walk-DependencyObject will walk the tree of the DepednedBy nodes'
[void](New-DependencyObject -name Level2SubB_A -DependOn ((Get-DOVariable | ? {$_.name -eq 'Level1SubB'})) -CreateVariable)
[void](New-DependencyObject -name Level3SubB_A_A -DependOn ((Get-DOVariable | ? {$_.name -eq 'Level2SubB_A'})) -CreateVariable)
Walk-DependencyObject (Get-DOVariable | ? {$_.name -eq 'Level1SubB'}) 

'Get-DOLinkedObjects retrieves linked *Objects* (not their guids)'
$anotherRoot | Get-DOLinkedObjects 

