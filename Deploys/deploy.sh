#!/bin/bash
# USAGE: bash Deploys/deploy.sh /path/to/AppTemplate.app
# Function to extract the app and create a zip
extract_and_zip() {
  local app_path="$1"

  # Check if the provided path is an .xcarchive
  # if [ ! -d "$archive_path" ] || [[ "$archive_path" != *.xcarchive ]]; then
  #   echo "Invalid path. Please provide a valid .xcarchive path."
  #   exit 1
  # fi

  # Define the path to the .app bundle inside the .xcarchive
  # local app_path="$archive_path/Products/Applications/AppTemplate.app"

  # Check if the .app bundle exists in the .xcarchive
  if [ ! -d "$app_path" ]; then
    echo ".app bundle not found in the specified .app file"
    exit 1
  fi

  # Define the path to the Info.plist file inside the .app bundle
  local info_plist="$app_path/Contents/Info.plist"

  # Check if the Info.plist file exists
  if [ ! -f "$info_plist" ]; then
    echo "Info.plist not found in the specified .app bundle."
    exit 1
  fi

  # Extract the short version string and version from the Info.plist file using PlistBuddy
  SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$info_plist")
  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$info_plist")

  # Check if the version was successfully extracted
  if [ -z "$VERSION" ] || [ -z "$SHORT_VERSION" ]; then
    echo "Failed to extract version information from Info.plist."
    exit 1
  fi

  # Create the Builds directory inside container folder if it doesn't exist
  BUILDS_DIR="./Deploys/Builds"
  mkdir -p "$BUILDS_DIR"

  # Create a new directory with the short version name inside the Builds directory
  NEW_DIR="$BUILDS_DIR/AppTemplate_$SHORT_VERSION"
  mkdir -p "$NEW_DIR"

  # Copy the .app bundle to the new directory
  cp -R "$app_path" "$NEW_DIR"

  # Define the zip file name
  ZIP_FILE="AppTemplate_$SHORT_VERSION.zip"
  ZIP_FILE_FULL_PATH="$NEW_DIR/$ZIP_FILE"

  # Compress the .app bundle into a zip file without parent directories
  (cd "$NEW_DIR" && ditto -c -k --keepParent "AppTemplate.app" "$ZIP_FILE")

  echo "The app has been compressed into $ZIP_FILE"
}

# Function to check and install gdrive using Homebrew if not present
check_and_install_gdrive() {
  if ! command -v gdrive &> /dev/null; then
    echo "gdrive is not installed. Installing gdrive using Homebrew..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
      echo "Homebrew is not installed. Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Tap the repository containing gdrive
    brew tap prasmussen/gdrive

    # Install gdrive
    brew install gdrive

    echo "gdrive installed successfully."
  else
    echo "gdrive is already installed."
  fi
}

# Function to upload to Google Drive and get the download URL
upload_to_gdrive() {
  local file_path="$1"
  local folder_id="$2"

  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
  fi

  # Upload the file to Google Drive in the specified folder
  FILE_ID=$(gdrive files upload --parent "$folder_id" "$file_path" | awk '/Id/ {print $2}')
  $(gdrive permissions share "$FILE_ID" --role reader --type anyone)
  # Check if the file ID was successfully retrieved
  if [ -z "$FILE_ID" ]; then
    echo "Failed to upload file to Google Drive."
    exit 1
  fi

  # Construct the downloadable URL
  DOWNLOAD_URL="https://drive.google.com/uc?export=download&id=$FILE_ID"

  echo "$DOWNLOAD_URL"
}

update_appcast_on_gdrive() {
  local appcast_path="$1"
  local file_id="$2"

  # Update the existing appcast.xml file on Google Drive
  gdrive files update "$file_id" "$appcast_path"
  echo "Appcast XML file updated on Google Drive."
}

# Function to generate the appcast.xml
generate_appcast() {
  local download_url="$1"
  # escaping the `&` character in the download URL
  download_url=$(echo "$download_url" | sed 's/&/\&amp;/g')
  echo "Download URL: $download_url"
  # Run the Sparkle sign_update tool
  SIGN_UPDATE_OUTPUT=$(Deploys/Sparkle/bin/sign_update "$ZIP_FILE_FULL_PATH")

  # Extract the signature and length from the output
  ED_SIGNATURE=$(echo "$SIGN_UPDATE_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
  LENGTH=$(echo "$SIGN_UPDATE_OUTPUT" | grep -o 'length="[0-9]*"' | cut -d'"' -f2)

  # Check if the signature and length were successfully extracted
  if [ -z "$ED_SIGNATURE" ] || [ -z "$LENGTH" ]; then
    echo "Failed to extract signature and length from sign_update output."
    exit 1
  fi

  # Prompt for additional inputs
  read -p "Enter the title for the appcast item: " ITEM_TITLE

  # Generate the current date in RFC 2822 format
  PUB_DATE=$(date -R)

  # Generate the appcast.xml file
  APPCAST_XML="$NEW_DIR/appcast.xml"
  cat > "$APPCAST_XML" <<EOL
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>AppTemplate</title>
        <item>
            <title>$ITEM_TITLE</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$VERSION</sparkle:version>
            <sparkle:shortVersionString>$SHORT_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure 
                       url="$download_url"
                       sparkle:edSignature="$ED_SIGNATURE" 
                       length="$LENGTH"
                       type="application/octet-stream"
                       />
        </item>
    </channel>
</rss>
EOL

  echo "Appcast XML file generated: $APPCAST_XML"
}

# Main script execution
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/AppTemplate.xcarchive"
  exit 1
fi

extract_and_zip "$1"

check_and_install_gdrive

FOLDER_ID="1RO6Q52a5Wfu9mEnkFpgnLjKC4a6-lb1K"
APPCAST_ID="1ylHf4cc7mQu1P9IFeyjWblsSCZ8og9l4"

# Upload the zip file and generate the appcast
DOWNLOAD_URL=$(upload_to_gdrive "$ZIP_FILE_FULL_PATH" "$FOLDER_ID")
echo "Download URL: $DOWNLOAD_URL"

generate_appcast "$DOWNLOAD_URL"

# Update the appcast.xml to Google Drive

update_appcast_on_gdrive "$APPCAST_XML" "$APPCAST_ID"

# Update Firestore with the new download URL
export PATH="/opt/homebrew/bin:$PATH" # assume python is installed with homebrew

# Check if the virtual environment directory exists
VENV_DIR="./Deploys/venv"
if [ ! -d "$VENV_DIR" ]; then
  # Create a virtual environment if it doesn't exist
  python3 -m venv "$VENV_DIR"
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"
pip install google-cloud-firestore
pip install google

export GOOGLE_APPLICATION_CREDENTIALS="./Deploys/SwiftClean_firestore.json" # For updating Firestore

PROJECT_ID="swiftclean-4a952"
COLLECTION="release_xml"
DOCUMENT="CbQaLWDGrIYWIvudtLtz"

python ./Deploys/update_firestore.py "$PROJECT_ID" "$COLLECTION" "$DOCUMENT" "$DOWNLOAD_URL"

# Deactivate the virtual environment
deactivate