if [[ -z "${GOOGLE_SERVICE_INFO}" ]]; then
  cat $GOOGLE_SERVICE_INFO > /Contractus/Resourses/GoogleService-Info.plist
  echo "Google service copied successfully"
else
  echo "No Google service"
fi