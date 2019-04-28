class HashType < ActiveModel::Type::Value
  def cast(value)
    value.transform_keys &:to_sym
  end
end

class ArrayOfHashesType < ActiveModel::Type::Value
  def cast(value)
    value.map { |h| h.transform_keys &:to_sym }
  end
end

ActiveModel::Type.register :hash, HashType
ActiveModel::Type.register :array_of_hashes, ArrayOfHashesType
