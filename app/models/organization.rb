# frozen_string_literal: true

class Organization < ApplicationRecord
  has_one  :organization,   foreign_key: :parent_organization
  has_many :organizations,  foreign_key: :parent_organization
  has_many :memberships,    dependent: :destroy

  validates :oid, :name, presence: true, uniqueness: true

  before_validation :assign_oid

  scope :with_parents, ->(id = nil) { where(parent_organization: id) }
  scope :with_all_memberships, -> { joins('LEFT JOIN memberships ON organizations.id = memberships.organization_id') }

  private

  def assign_oid
    return unless oid.blank?

    self.oid = UIDGenerator.generate(Barong::App.config.oid_prefix)
  end
end

# == Schema Information
# Schema version: 20210514034514
#
# Table name: organizations
#
#  id                  :bigint           not null, primary key
#  oid                 :string(255)      not null
#  parent_organization :bigint
#  name                :string(255)      not null
#  group               :string(255)
#  email               :string(255)
#  country             :string(255)
#  city                :string(255)
#  phone               :string(255)
#  address             :string(255)
#  postcode            :string(255)
#  status              :string(255)      default("active"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_organizations_on_oid  (oid) UNIQUE
#