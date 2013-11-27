require 'oauth/request_proxy/base'
require 'uri'
require 'rack'

module OAuth::RequestProxy
  class RackRequest < OAuth::RequestProxy::Base
    proxies Rack::Request

    def method
      request.env["rack.methodoverride.original_method"] || request.request_method
    end

    def uri
      request.url
    end

    def parameters
      if options[:clobber_request]
        options[:parameters] || {}
      else
        params = request_params.merge(query_params).merge(header_params)
        params.merge(options[:parameters] || {})
      end
    end

    def signature
      parameters['oauth_signature']
    end

  protected

    def query_params
      normalize_first_level_arrays(request.GET)
    end

    def request_params
      if request.content_type and request.content_type.to_s.downcase.start_with?("application/x-www-form-urlencoded")
        normalize_first_level_arrays(request.POST)
      else
        {}
      end
    end

    def normalize_first_level_arrays(params)
      normalized_params = params.dup

      params.each do |k,values| 
        if values.is_a?(Array)
          values.each do |v|
            normalized_params["#{k}[]"]||=[]
            normalized_params["#{k}[]"] << v
          end
          normalized_params.delete(k)
        end
      end

      normalized_params
    end
  end
end
