# encoding: UTF-8

class AssociationCache < ActiveRecord::Base
  def self.create_manager(associations)
    manager = AssociationManager.new

    associations.each do |assoc|
      type_const = const_for_assoc_type(assoc['type'])

      manager.addAssociation(
        assoc['first'], assoc['second'], type_const,
        non_empty_string_or_nil(assoc['association_name']),
        non_empty_string_or_nil(assoc['foreign_key'])
      )
    end

    manager
  end

  private

  def self.const_for_assoc_type(type)
    AssociationType.const_get(type.upcase.to_sym)
  end

  def self.non_empty_string_or_nil(str)
    str if str && !str.strip.empty?
  end
end