
# DependencyObject
PSObject to build simple hierarchical structures

This module uses PS v5 classes.

Example: 

```
$root = New-DependencyObject -Name 'Services infrastructure' -Type 'root'
$r00auto02 = New-DependencyObject -n 'r00auto02' -t 'os' -SubType 'windows' -DependOn $root
$r00rmq01 = New-DependencyObject -n 'r00rmq01' -t 'os' -SubType 'windows' -DependOn $root

$rmq_service = New-DependencyObject 'RabbitMQ' -Type 'service' -DependOn $r00rmq01
$rmq_port = New-DependencyObject 'RabbitMQ' -Value '5989' -Type 'port' -DependOn $rmq_service

" find parent object: "
Get-DOVariable | ? guid -eq $rmq_port.DependOn.guid | select name,type

"  "
" get all parents: "
$rmq_port | Walk-DependencyObject -DependOn | select name,type
```
