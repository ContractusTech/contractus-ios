if [[ -z "${GOOGLE_SERVICE_INFO}" ]]; then
      echo "No Google service"
else
    echo $GOOGLE_SERVICE_INFO > ../Contractus/Resources/GoogleService-Info.plist
      echo "GoogleService-Info.plist set successfully"
fi

echo "Product: $CI_PRODUCT"

cd ../Contractus/
INFOPLIST_NAME="Info.plist"
if [ "$CI_PRODUCT" == "Wallet" ]; then
    INFOPLIST_NAME="Wallet-Info.plist"
fi

echo "PLIST: $INFOPLIST_NAME"

plutil -replace APPLE_APP_ID -string $APPLE_APP_ID $INFOPLIST_NAME
plutil -replace APPSFLYER_DEV_KEY -string $APPSFLYER_DEV_KEY $INFOPLIST_NAME
