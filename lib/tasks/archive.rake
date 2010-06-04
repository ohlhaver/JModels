namespace :archive do
  
  desc "Archive and Delete Data Older than 1 Month"
  task :old_data => :environment do
    $0 = 'story_archiver'
    StoryArchiver.run( :mode => :production, :max_docs => 100_000 )
  end
  
  desc "Test Archive Data Older than 1 Month (Does not delete)"
  task :test => :environment do
    StoryArchiver.run( :mode => :test, :max_docs => 10_000 )
  end
  
end