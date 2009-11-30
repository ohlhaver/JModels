namespace :authors do
  
  desc "Clean authors database"
  task :clean => :environment do
    cleaning = AuthorCleaning.new( :logfile => STDOUT )
    cleaning.start
  end
  
end