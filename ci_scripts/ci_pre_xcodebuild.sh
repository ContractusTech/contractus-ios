if [[ -z "${GOOGLE_SERVICE_INFO}" ]]; then
  	echo "No Google service"
else
	echo $GOOGLE_SERVICE_INFO > ../Contractus/Resources/GoogleService-Info.plist
  	echo "GoogleService-Info.plist set successfully"
fi

cd ../Contractus/

plutil -replace APPLE_APP_ID -string $APPLE_APP_ID Info.plist
plutil -replace APPSFLYER_DEV_KEY -string $APPSFLYER_DEV_KEY Info.plist
# Put here
