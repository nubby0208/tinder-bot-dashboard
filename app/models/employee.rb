class Employee < User
  default_scope { where.not(employer_id: nil) }
end
