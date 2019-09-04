dest_dir=${1:-'/Users/abisarvepalli/Downloads'}

# Compress src files and package file
echo "### Packaging build-lib dir ###"

build_lib_dir="blockchain-build-lib"
echo ">>> cp -r src $build_lib_dir"
cp -r src $build_lib_dir

cd $build_lib_dir
tar -cvzf ../$build_lib_dir.tgz *
cd ../
rm -rf $build_lib_dir


# Move packaged file to desktop
echo "### Moving packaged directory to $dest_dir ###"
echo ">>> mv $build_lib_dir.tgz $dest_dir"
mv $build_lib_dir.tgz $dest_dir


# Going to delete file in 30 seconds
echo
echo "~~~ Deleting built package in 20 seconds ~~~"
sleep 20
echo ">>> rm ${dest_dir}/${build_lib_dir}.tgz"
rm ${dest_dir}/${build_lib_dir}.tgz
