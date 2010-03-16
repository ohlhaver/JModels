class Clustering < BackgroundRunnerPool
  
  def initialize( options = {} )
    super( options )
    $new_stories_count = 0
    #ActiveRecord::Base.logger.level = 0
    
    if options[:test]
      
      unless options[:skip_migration]
        add_runner( 'Background Migrations', :run_once ) do
          BackgroundMigration.new.clear_database # clear tables from background db only
          BackgroundMigration.new( :logger => self.logger ).run
        end
      end
      
      add_runner( 'Candidate Stories Generation', :run_once ) do
        t = Story.maximum(:created_at)
        CandidateGeneration.new( :logger => self.logger ).run( :with_session => true, :start => { :time => t } )
      end
    
      add_runner( 'Duplicate Deletion Within Source', :run_once ) do
        DuplicateDeletion.new( :logger => self.logger ).run( :with_session => true )
      end
    
      add_runner( 'Story Groups Generation', :run_once ) do
        GroupGeneration.new( :logger => self.logger ).run( :with_session => true )
      end
      
      # add_runner( 'Duplicate Marker Across Source', :run_once ) do
      #   DuplicateMarker.new( :logger => self.logger ).run( :with_session => true )
      # end
      
      # Queries runs on the Tier2 MySQL DB rather than Background Mysql DB ( therefore running every 30 minutes rather than :run_forever )
      add_runner( 'Top Author Stories', :run_once ) do
        TopAuthorGeneration.new( :logger => self.logger ).run( :with_session => true )
      end
    
    else
      
      add_runner( 'Background Migrations', :run_every_day ) do
        BackgroundMigration.new( :logger => self.logger, :parent => self ).run
      end
    
      add_runner( 'Candidate Stories Generation', :run_forever ) do
        CandidateGeneration.new( :logger => self.logger, :parent => self ).run( :with_session => true )
      end
    
      add_runner( 'Duplicate Deletion Within Source', :run_forever ) do
        unless $new_stories_count == 0
          DuplicateDeletion.new( :logger => self.logger, :parent => self ).run( :with_session => true )
        end
      end
    
      add_runner( 'Story Groups Generation', :run_forever ) do
        GroupGeneration.new( :logger => self.logger, :parent => self ).run( :with_session => true )
      end
      
      # add_runner( 'Duplicate Marker Across Source', :run_forever ) do
      #   unless $new_stories_count == 0
      #     DuplicateMarker.new( :logger => self.logger, :parent => self ).run( :with_session => true )
      #   end
      # end
      
      # Queries runs on the Tier2 MySQL DB rather than Background Mysql DB ( therefore running every hour rather than :run_forever )
      # New top authors are calculated and top author stories is reset
      add_runner( 'Top Author Stories', :run_every_hour ) do
        TopAuthorGeneration.new( :logger => self.logger ).run( :with_session => true )
      end
    
    end
    
  end
  
end