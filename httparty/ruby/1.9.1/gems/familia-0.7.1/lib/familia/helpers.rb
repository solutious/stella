
module Familia
  #
  #     class Example
  #       include Familia
  #       field :name
  #       include Familia::Stamps
  #     end 
  #
  module Stamps
    def self.included(obj)
      obj.module_eval do
        field :created => Integer
        field :updated => Integer
        def init_stamps
          now = Time.now.utc.to_i
          @created ||= now
          @updated ||= now 
        end
        def created
          @created ||= Time.now.utc.to_i
        end
        def updated
          @updated ||= Time.now.utc.to_i
        end
        def created_age
          Time.now.utc.to_i-created
        end
        def updated_age
          Time.now.utc.to_i-updated
        end
        def update_time
          @updated = Time.now.utc.to_i
        end
        def update_time!
          update_time
          save if respond_to? :save
          @updated
        end
      end
    end
  end
  module Status
    def self.included(obj)
      obj.module_eval do
        field :status
        field :message
        def  failure?()        status? 'failure'       end
        def  success?()        status? 'success'       end
        def  pending?()        status? 'pending'       end
        def  expired?()        status? 'expired'       end
        def disabled?()        status? 'disabled'      end
        def  failure!(msg=nil) status! 'failure',  msg end
        def  success!(msg=nil) status! 'success',  msg end
        def  pending!(msg=nil) status! 'pending',  msg end
        def  expired!(msg=nil) status! 'expired',  msg end
        def disabled!(msg=nil) status! 'disabled', msg end
        private
        def status?(s)
          status.to_s == s.to_s
        end
        def status!(s, msg=nil)
          @updated = Time.now.utc.to_f
          @status, @message = s, msg
          save if respond_to? :save
        end
      end
    end
  end
end
