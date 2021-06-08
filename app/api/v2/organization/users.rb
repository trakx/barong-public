# frozen_string_literal: true

module API
  module V2
    module Organization
      class Users < Grape::API
        resource :users do
          helpers ::API::V2::NamedParams

          desc 'Return organization users',
               failure: [
                 { code: 400, message: 'Required params are missing' },
                 { code: 401, message: 'Organization ability not permitted' },
                 { code: 404, message: 'Record does not exists' },
                 { code: 422, message: 'Validation errors' }
               ],
               success: API::V2::Organization::Entities::Membership
          params do
            requires :oid,
                     type: String,
                     desc: 'organization oid'
          end
          get do
            unless organization_ability? :read, ::Organization
              error!({ errors: ['organization.ability.not_permitted'] }, 401)
            end

            org = ::Organization.find_by_oid(params[:oid])
            error!({ errors: ['organization.organization.doesnt_exist'] }, 404) if org.nil?

            oids = [org.id]
            oids.concat(::Organization.with_parents(org.id).pluck(:id)) if org.parent_organization.nil?
            members = ::Membership.with_organizations(oids)

            present members, with: API::V2::Organization::Entities::Membership
          end
        end

        resource :user do
          helpers ::API::V2::NamedParams

          desc 'Add user into organization',
               failure: [
                 { code: 400, message: 'Required params are missing' },
                 { code: 401, message: 'Organization ability not permitted' },
                 { code: 404, message: 'Record does not exists' },
                 { code: 422, message: 'Validation errors' }
               ],
               success: { code: 200, message: 'User of organization was deleted' }
          params do
            requires :uid,
                     type: String,
                     desc: 'user uid'
            requires :oid,
                     type: String,
                     desc: 'organization oid'
            requires :role,
                     type: String,
                     desc: 'organization user role'
          end
          post do
            unless organization_ability? :create, ::Organization
              error!({ errors: ['organization.ability.not_permitted'] }, 401)
            end

            user = ::User.find_by_uid(params[:uid])
            org = ::Organization.find_by_oid(params[:oid])
            error!({ errors: ['organization.membership.doesnt_exist'] }, 404) if user.nil? || org.nil?

            members = ::Membership.with_users(user.id)
            if !members.nil? && members.length.positive?
              user_org = members.first.organization
              if user_org.parent_organization.nil?
                # User already be org admin; cannot add duplication.
                error!({ errors: ['organization.membership.already_exist'] }, 401)
              end
              # User already have subunit; Try to add in another subunit
              if (members.select { |m| m.organization.id == org.id }).length.positive?
                # Found duplication; return error
                error!({ errors: ['organization.membership.already_exist'] }, 401)
              end
            end

            member = ::Membership.new({ user_id: user.id, organization_id: org.id, role: params[:role] })
            code_error!(member.errors.details, 422) unless member.save

            present member, with: API::V2::Organization::Entities::Membership
          end

          desc 'Delete user in organization',
               failure: [
                 { code: 400, message: 'Required params are missing' },
                 { code: 401, message: 'Organization ability not permitted' },
                 { code: 404, message: 'Record does not exists' },
                 { code: 422, message: 'Validation errors' }
               ],
               success: { code: 200, message: 'User of organization was deleted' }
          params do
            requires :membership_id,
                     type: Integer,
                     desc: 'membership id'
          end
          delete do
            unless organization_ability? :destroy, ::Organization
              error!({ errors: ['organization.ability.not_permitted'] }, 401)
            end

            member = ::Membership.find(params[:membership_id])
            error!({ errors: ['organization.membership.doesnt_exist'] }, 404) if member.nil?

            member.destroy
            status 200
          end
        end
      end
    end
  end
end