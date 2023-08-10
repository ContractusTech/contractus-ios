if [[ -z "${GOOGLE_SERVICE_INFO}" ]]; then
  	echo "No Google service"
else
	echo $GOOGLE_SERVICE_INFO > ../Contractus/Resources/GoogleService-Info.plist
  	echo "GoogleService-Info.plist set successfully"
fi