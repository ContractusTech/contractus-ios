echo "Post build"

if [ "$CI_WORKFLOW" = "TestFlight Release Build" ];
then
    echo "Uploading Symbols To Firebase"
    # Add your path to the GoogleService-Info.plist & add in your app name.
    # upload-symbols script can be copied from your firebase crashlytics frameowkr directory
    ./upload-symbols -gsp ./../Contractus/Resources/GoogleService-Info.plist -p ios $CI_ARCHIVE_PATH/dSYMs/Contractus.app.dSYM
fi
