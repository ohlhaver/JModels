namespace :sitemaps do
  
  desc "Generate Sitemaps"
  task :generate => :environment do
    Sitemap.run
  end
  
  desc "Test Sitemaps"
  task :test => :environment do
    Sitemap.run( :test )
  end
  
end