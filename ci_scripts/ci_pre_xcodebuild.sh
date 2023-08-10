if [[ -z "${GOOGLE_SERVICE_INFO}" ]]; then
  	echo "No Google service"
else
	cat $GOOGLE_SERVICE_INFO > /Contractus/Resourses/GoogleService-Info.plist
  	echo "Google service copied successfully"
fi