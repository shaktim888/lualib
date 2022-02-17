#！/bin/bash
pushd `dirname $0`

function updateVersion
{
	local File=$1
	local Time=`date '+%Y.%m.%d'`
	if [ ! -f "$File.back" ]; then
		cp $File $File.back
	fi

	sed -n "s/\(s\.version *= *\)'[0-9\.]*'\( *\)$/\1'$Time'\2/;w $File" $File.back
	rm $File.back
}

updateVersion lualibPod.podspec

popd