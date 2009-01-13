$: << File.dirname(__FILE__)
require 'spec-helper'

require 'time'
require 'date'
require 'stella/storable'

class TeaCup < Stella::Storable

  field :owner => String
  field :volume => Float
  field :washed => TrueClass
  field :last_used => Time
  
end


describe 'Stella::Storable' do
  FILE_PATH = File.join(STELLA_HOME, "test-spec-tmp", "tc")
  RECORD = {
    :owner => "stella", 
    :volume => 97.01, 
    :washed => true, 
    :last_used => (Time.now-100).utc
  }
  
  before(:all) do
    FileUtil.create_dir(File.dirname(FILE_PATH), '.')
  end
  
  before(:each) do
    @generated_files ||= []
  end
  
  after(:each) do
  end
  
  after(:all) do
    (@generated_files || []).each do |file| 
      File.unlink(@file) if File.exists?(@file) 
    end
  end
  
  Stella::Storable::SUPPORTED_FORMATS.each do |format|
	  next if format == 'json' && !::HAS_JSON
    it "creates object from hash and saves in #{format} format" do
      teacup = TeaCup.from_hash(RECORD)
      path = "#{FILE_PATH}.#{format}"
      @generated_files << path
      teacup.to_file(path)
      File.exists?(path).should.equal true
    end
  end
  
  Stella::Storable::SUPPORTED_FORMATS.each do |format|
	  next if format == 'json' && !::HAS_JSON
    it "loads object from #{format} file" do
      teacup = TeaCup.from_file("#{FILE_PATH}.#{format}")
      tchash = teacup.to_hash
      tchash.should.be.instance_of Hash
      tchash.keys.should.equal RECORD.keys
      tchash[:volume].should.equal RECORD[:volume]
      tchash[:last_used].to_i.should.equal RECORD[:last_used].to_i
      tchash[:washed].should.equal RECORD[:washed]
    end
  end
  
end