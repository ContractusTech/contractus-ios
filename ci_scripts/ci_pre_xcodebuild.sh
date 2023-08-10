if [[ -z "${GOOGLE_SERVICE_INFO}" ]]; then
  	echo "No Google service"
else
	echo $GOOGLE_SERVICE_INFO > ./Contractus/Resources/GoogleService-Info.plist
  	echo "Google service copied successfully"
fi