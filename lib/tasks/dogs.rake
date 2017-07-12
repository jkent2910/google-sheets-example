require "googleauth"
require "google_drive"

namespace :google_sheets_example do

  desc "Updates dogs table from Google spreadsheet"
  task update_dogs: :environment do
    spreadsheet_name = "dogs_rule"

    ENV["GOOGLE_APPLICATION_CREDENTIALS"] = Rails.root.join("config", "google_creds.json").to_path
    ENV["SSL_CERT_FILE"] = $LOAD_PATH.grep(/google-api-client/).first + "/cacerts.pem"

    credentials = Google::Auth.get_application_default
    credentials.scope = ["https://www.googleapis.com/auth/drive", "https://spreadsheets.google.com/feeds/"]
    credentials.fetch_access_token!
    access_token = credentials.access_token

    drive_session = GoogleDrive.login_with_oauth(access_token)

    spreadsheet = drive_session.spreadsheet_by_title(spreadsheet_name)
    raise "Spreadsheet #{spreadsheet_name} not found" unless spreadsheet
    worksheet = spreadsheet.worksheets.first

    attrs = worksheet.rows.first.map(&:to_sym)

    worksheet.rows.drop(1).each do |row|
      dog_attrs = attrs.zip(row).to_h
      dog = Dog.find_or_initialize_by(id: dog_attrs[:id])
      if dog.persisted?
        puts "Updating #{dog.name}"
      else
        puts "Adding #{dog_attrs[:name]}"
      end
      dog.update_attributes(dog_attrs)
    end
  end
end
