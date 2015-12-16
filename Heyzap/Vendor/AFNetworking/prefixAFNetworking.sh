#!/bin/bash

# This script namespaces AFNetworking
# To use the script, delete the existing AFNetworking files and replace them with the updated version
# Then run this script from Heyzap/Vendor/AFNetworking

for f in *.{h,m}; do mv $f HZ$f ; done

sed -i "" -- 's/AF/HZAF/g' *.{h,m}
sed -i "" -- 's/com.alamofire/com.heyzap.alamofire/g' *.{h,m}
sed -i "" -- 's/af_/hz_af_/g' *.{h,m}

names=( url_request_operation_completion_group \
url_request_operation_completion_queue \
http_request_operation_processing_queue \
http_request_operation_completion_group \
url_session_manager_creation_queue \
url_session_manager_processing_queue )

for name in "${names[@]}"
do
  sed -i "" -- "s/${name}/hz_${name}/g" *.{h,m}
done
