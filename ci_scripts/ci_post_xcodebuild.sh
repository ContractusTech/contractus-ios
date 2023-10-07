echo "[Post build] Uploading Symbols To Firebase"

./upload-symbols -gsp ./../Contractus/Resources/GoogleService-Info.plist -p ios $CI_ARCHIVE_PATH/dSYMs/Contractus.app.dSYM

echo "Upload success"
