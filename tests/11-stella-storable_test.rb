$: << File.dirname(__FILE__)
require 'spec-helper'

require 'date'
require 'stella/storable'

class TeaCup < Stella::Storable
  attr_accessor :owner, :volume, :washed, :dates_used
  def field_names
    [ :owner, :volume, :washed, :dates_used ]
  end
end

describe 'Stella::Storable' do
  FILE_PATH = File.join(STELLA_HOME, "test-spec-tmp", "tc")
  RECORD = {
    :owner => "stella", 
    :volume => 97.01, 
    :washed => true, 
    :dates_used => [DateTime.now, DateTime.now-10, DateTime.now-100]
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
  
  Stella::Storable::SupportedFormats.each do |format|
    it "creates object from hash and saves in #{format} format" do
      teacup = TeaCup.from_hash(RECORD)
      path = "#{FILE_PATH}.#{format}"
      @generated_files << path
      teacup.to_file(path)
      File.exists?(path).should.equal true
    end
  end
  
  Stella::Storable::SupportedFormats.each do |format|
    it "loads object from #{format} file" do
      teacup = TeaCup.from_file("#{FILE_PATH}.#{format}")
      (teacup.to_hash.keys == RECORD.to_hash.keys).should.equal true
    end
  end
  
end