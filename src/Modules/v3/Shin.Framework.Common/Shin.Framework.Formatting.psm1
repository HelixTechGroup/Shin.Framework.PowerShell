#
# Deloitte.GTS.CTO.Formatting.psm1
#

function ConvertTo-FileSizeFromBytes([float]$size) {
		if (($size/1024) -ge 1024) {
			$free = $size/1024/1024;
			if ($free -ge 1024) {
				$free /= 1024;
				if ($free -ge 1024) {
					$free /= 1024;
					$fPostfix = "TB";
				}else {
					$fPostfix = "GB"
				}
			}else{
				$fPostfix = "MB";
			}
		} else {
			$free = $size/1024;
			$fPostfix = "KB";
		}
	
		$free = [Math]::Round($free, 2);
		return "$free$fPostfix";
	}	

function ConvertTo-LdapDN([string]$domain, [string]$objectPath) {
	$path = "";
	$dc = $domain.Split('.');
	$op = $objectPath.Split('\');
	
	foreach ($d in $dc) {
		$path += ",DC=$d";
	}
	
	foreach ($o in $op) {
		$path = ",OU=$o" + $path;
	}

	return $path -replace '^(.*?),', '$1';
}

Export-ModuleMember -Function *-*