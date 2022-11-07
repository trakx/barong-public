# frozen_string_literal: true

require_dependency 'barong/jwt'

module API::V2
  module Utils
    def remote_ip
      # default behaviour, IP from HTTP_X_FORWARDED_FOR
      ip = env['action_dispatch.remote_ip'].to_s

      if Barong::App.config.gateway == 'akamai'
        # custom header that contains only client IP
        true_client_ip = request.env['HTTP_TRUE_CLIENT_IP'].to_s
        # take IP from TRUE_CLIENT_IP only if its not nil or empty
        ip = true_client_ip unless true_client_ip.nil? || true_client_ip.empty?
      end

      Rails.logger.debug "User login IP address: #{ip}"
      return ip
    end

    def code_error!(errors, code)
      final = errors.inject([]) do |result, (key, errs)|
        result.concat(
          errs.map { |e| e.values.first }
                .uniq
                .flatten
                .map { |e| [key, e].join('.') }
        )
      end
      error!({ errors: final }, code)
    end

    def admin_authorize!(*args)
      AdminAbility.new(current_user).authorize!(*args)
    rescue CanCan::AccessDenied
      error!({ errors: ['admin.ability.not_permitted'] }, 401)
    end

    def verify_auth0_mfa!
      error!({ errors: ['resource.api_key.missing_mfa'] }, 401) unless headers['X-Auth-Auth0-Token']
      #error!({ errors: ['resource.api_key.missing_mfa - without authorization header'] }, 401) unless headers['Authorization']

      jwtToken = headers['X-Auth-Auth0-Token'].to_s
      #jwtToken = headers['Authorization'].gsub('Bearer ', '')
      claims = Barong::Auth0::JWT.verify(jwtToken).first

      error!({ errors: ['resource.api_key.missing_mfa - without updated_at'] }, 401) unless claims.key?('updated_at')
      error!({ errors: ['resource.api_key.missing_mfa - without auth_methods'] }, 401) unless claims.key?('auth_methods')

      authMethods = claims['auth_methods']
      error!({ errors: ['resource.api_key.missing_mfa - without mfa in auth_methods', authMethods.include] }, 401) unless authMethods.include? 'mfa'

      timestamp = claims['updated_at'].to_i
      error!({ errors: ['resource.api_key.expired_mfa'] }, 401) unless timestamp > 0

      nonce_timestamp_window = ((Time.now.to_f * 1000).to_i - timestamp).abs
      error!({ errors: ['resource.api_key.expired_mfa'] }, 401) if nonce_timestamp_window >= Barong::App.config.auth0_mfa_lifetime

      return true
    end
  end
end
