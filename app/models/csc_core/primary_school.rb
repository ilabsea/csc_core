module CscCore
  class PrimarySchool < ApplicationRecord
    self.table_name = "primary_schools"

    validates :code, presence: true, uniqueness: true
    validates :name_km, presence: true, uniqueness: { scope: :commune_id }
    validates :name_en, presence: true, uniqueness: { scope: :commune_id }
    validates :commune_id, presence: true
    validates :district_id, presence: true
    validates :province_id, presence: true

    def name
      self["name_#{I18n.locale}"]
    end

    def address
      address_code = commune_id.presence || district_id.presence || province_id.presence
      return if address_code.nil?

      "Pumi::#{Location.location_kind(address_code).titlecase}".constantize.find_by_id(address_code).try("address_#{I18n.locale}".to_sym)
    end

    def self.filter(params)
      scope = all
      scope = scope.where("code LIKE ? OR name_en LIKE ? OR name_km LIKE ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?
      scope = scope.where(commune_id: params[:commune_id]) if params[:commune_id].present?
      scope = scope.where(district_id: params[:district_id]) if params[:district_id].present?
      scope = scope.where(province_id: params[:province_id]) if params[:province_id].present?
      scope
    end
  end
end