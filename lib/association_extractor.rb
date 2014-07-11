# encoding: UTF-8

require 'jruby-parser'
require 'active_support'

# extracts association information from a rails model
class AssociationExtractor
  class << self

    def extract_associations(ruby_code)
      root = JRubyParser.parse(ruby_code)
      find_active_record_classes_in(root).flat_map do |ar_class_node|
        extract_associations_from_ar_class_node(ar_class_node)
      end
    end

    private

    def extract_associations_from_ar_class_node(ar_class_node)
      find_association_function_calls_in(ar_class_node).map do |node|
        extract_association_from_function_call_node(ar_class_node, node)
      end
    end

    def extract_association_from_function_call_node(ar_class_node, node)
      if node.args_node.size > 1 && (hash_arg = node.args_node[1]).is_a?(Java::OrgJrubyparserAst::HashNode)
        class_name = read_from_hash(hash_arg, 'class_name')
        foreign_key = read_from_hash(hash_arg, 'association_foreign_key')
      end

      association_name = node.args_node[0].name
      parent_class_name = ar_class_node.cpath.to_source.split('::').last

      # first: the name of the parent SQL table
      # second: the name of the associated SQL table
      # type: the kind of association (has_many, belongs_to, etc)
      # foreign_key: the column to use in the join clause
      # association_name: the ActiveRecord name for the association (may or may not match an inflected `second`)
      result = {
        first: to_sql_table_name(parent_class_name),
        second: to_sql_table_name(class_name || association_name),
        type: node.name.to_sym,
        foreign_key: foreign_key,
        association_name: association_name
      }

      result.each_with_object({}) do |(key, val), ret|
        ret[key] = val if val
      end
    end

    def to_sql_table_name(name)
      if name
        ActiveSupport::Inflector.pluralize(
          ActiveSupport::Inflector.underscore(name)
        )
      end
    end

    def find_active_record_classes_in(tree)
      tree.find_all.select do |node|
        node.short_name == 'class' && node.get_super && node.get_super.to_source == 'ActiveRecord::Base'
      end
    end

    def find_association_function_calls_in(tree)
      tree.find_all.select do |node|
        node.short_name == 'fcall' && assoc_method?(node.name)
      end
    end

    def read_from_hash(hash_node, key)
      # shave off the first two nodes which are a HashNode and ArrayNode respectively
      found_slice = hash_node.to_a[2..-1].each_slice(2).find do |slice|
        get_value(slice.first) == key
      end

      get_value(found_slice.last) if found_slice
    end

    def get_value(textual_node)
      case textual_node
        when Java::OrgJrubyparserAst::SymbolNode
          textual_node.name
        when Java::OrgJrubyparserAst::StrNode
          textual_node.value
        else
          ""
      end
    end

    def assoc_method?(name)
      case name
        when 'belongs_to', 'has_many', 'has_one', 'has_and_belongs_to_many'
          true
        else
          false
      end
    end

  end
end
