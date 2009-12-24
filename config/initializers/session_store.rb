# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_JModel_session',
  :secret      => '44ed9e9871aad02fe99970c5e9d2ca5a0c845fd498adaadbbd807622fc6b8e279df7c980a6acabb8cbba3415788b4a8fbd775db955359ad20959f2c2698016b2'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
