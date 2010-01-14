$email_database_config = YAML.load_file( File.join( RAILS_ROOT, '/config/email.yml' ) )

class EnqueuedEmail < ActiveRecord::Base
  self.establish_connection( $email_database_config[ RAILS_ENV ] ) 
end

# Crontab Task
# 0,15,30,45 * * * * /usr/bin/ar_sendmail -o -b 900
