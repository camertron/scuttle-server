# encoding: UTF-8

class AssociationCache < ActiveRecord::Base
  def self.create_manager(associations)
    manager = AssociationManager.new

    associations.each do |assoc|
      type_const = const_for_assoc_type(assoc['type'])

      manager.addAssociation(
        assoc['first'], assoc['second'], type_const,
        assoc['association_name'], assoc['foreign_key']
      )
    end

    manager
  end

  private

  def self.const_for_assoc_type(type)
    AssociationType.const_get(type.upcase)
  end
end