#
# JARFIND finds a Java Class into the given path
# @author Diego Brondo <jamesbrond@gmail.com>
#
# Usage: jarfind <Path> <ClassName>
# Example: jarfind lib Log4j
#

if ($args.Length -eq 2) {
    $path = $args[0];
	$class = $args[1];
	$items = Get-ChildItem -Path "$path\*.jar";
	foreach ($item in $items) {
		if ($item.Attributes -ne "Directory") {
			# Uncomment this line if you want a more verbose output
			Write-Host "Search in $item";
			jar tf $item | findstr "$class"
		}
	}
} else {
	Write-Host "Usage: jarfind PATH CLASS";
}

