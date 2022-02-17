#!/bin/
set -x
work_path=$(cd `dirname $0`; pwd)
rm -rf $work_path/../../luaLib_temp
cp -r -f $work_path/../../luaLib $work_path/../../luaLib_temp
# echo $work_path
lc_work_path=$work_path/../../luaLib_temp
lib_work_path=$work_path/../../lualibPod

$work_path/HYCodeScan.app/Contents/MacOS/HYCodeScan --redefine -i $lc_work_path/lualib/luacore.h -i $lc_work_path/HYObfuscation.h
# $work_path/HYCodeScan.app/Contents/MacOS/HYCodeScan --xcode --config $work_path/appConfig.json -p $lc_work_path/lualib.xcodeproj

function randstr() {
  index=0
  str=""
  for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {1..6}; do str="$str${arr[$RANDOM%$index]}"; done
  echo $str
}

xcodebuild -project $lc_work_path/lualib.xcodeproj -scheme lualib -sdk iphoneos -configuration Release build -jobs 8

sh $lib_work_path/updateVersion.sh

productFolder="achieve"
for i in `ls $lc_work_path/$productFolder`; do
cp -rf $lc_work_path/$productFolder/$i $lib_work_path/framework/
done

for i in `ls $lib_work_path/res`; do
	fileName=`randstr`
	mv $lib_work_path/res/$i  $lib_work_path/res/$fileName.id
done

function comit()
{
	cd $lib_work_path
	git add -A && git commit -m 'autobuild' && git push origin master
}

comit
